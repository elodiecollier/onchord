/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions/v2";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

setGlobalOptions({maxInstances: 10, region: "us-east1"});

// eslint-disable-next-line @typescript-eslint/no-var-requires
const serviceAccount = require("../serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export const healthcheck = onRequest((req, res) => {
  logger.info("healthcheck hit", {method: req.method, path: req.path});
  res.status(200).json({ok: true, service: "onchord-backend"});
});

type SpotifyTokenResponse = {
  access_token: string;
  token_type: string;
  scope?: string;
  expires_in: number;
  refresh_token?: string;
  error?: string;
  error_description?: string;
};

/**
 * Get a valid Spotify access token for a user.
 * Reuses the cached token if still valid (60s buffer).
 * @param {string} uid - Firebase user ID.
 * @return {Promise<string>} A valid Spotify access token.
 */
async function getSpotifyAccessToken(
  uid: string
): Promise<string> {
  const docRef = admin
    .firestore().collection("spotifyTokens").doc(uid);
  const docSnap = await docRef.get();

  if (!docSnap.exists) {
    throw Object.assign(new Error("No Spotify tokens found"), {status: 404});
  }

  const data = docSnap.data() as {
    refreshToken?: string;
    accessToken?: string;
    expiresAt?: number;
  };

  // Return cached token if still valid (60s buffer)
  const now = Date.now();
  if (data.accessToken && data.expiresAt && data.expiresAt > now + 60_000) {
    return data.accessToken;
  }

  const refreshToken = data.refreshToken;
  if (!refreshToken) {
    throw Object.assign(new Error("Missing refreshToken"), {status: 400});
  }

  const clientId = process.env.SPOTIFY_CLIENT_ID;
  if (!clientId) {
    throw Object.assign(new Error("Missing SPOTIFY_CLIENT_ID"), {status: 500});
  }

  const refreshParams = new URLSearchParams();
  refreshParams.set("client_id", clientId);
  refreshParams.set("grant_type", "refresh_token");
  refreshParams.set("refresh_token", refreshToken);

  const refreshResp = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: refreshParams.toString(),
  });

  const refreshJson = await refreshResp.json();

  if (!refreshResp.ok) {
    throw Object.assign(
      new Error(refreshJson.error_description || "Token refresh failed"),
      {status: refreshResp.status, body: refreshJson}
    );
  }

  const accessToken = refreshJson.access_token as string;
  const expiresAt = now + (refreshJson.expires_in as number) * 1000;

  // Save new access token (and rotated refresh token if issued)
  const updateData: Record<string, unknown> = {
    accessToken,
    expiresAt,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (refreshJson.refresh_token) {
    updateData.refreshToken = refreshJson.refresh_token;
  }
  try {
    await docRef.update(updateData);
  } catch (e) {
    logger.warn("Failed to save refreshed tokens", e);
  }

  return accessToken;
}

export const spotifyExchange = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const authHeader = req.header("Authorization") || "";
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) {
      res.status(401).json({error: "Missing Authorization Bearer token"});
      return;
    }

    const idToken = match[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const body = (req.body ?? {}) as Record<string, unknown>;
    const code = body["code"];
    const codeVerifier = body["codeVerifier"];
    const redirectUri = body["redirectUri"];

    if (
      typeof code !== "string" ||
        typeof codeVerifier !== "string" ||
        typeof redirectUri !== "string"
    ) {
      res.status(400).json({
        error: "Missing or invalid code, codeVerifier, or redirectUri",
      });
      return;
    }

    const clientId = process.env.SPOTIFY_CLIENT_ID;
    if (!clientId) {
      res.status(500).json({error: "Missing SPOTIFY_CLIENT_ID env var"});
      return;
    }

    const params = new URLSearchParams();
    params.set("client_id", clientId);
    params.set("grant_type", "authorization_code");
    params.set("code", code);
    params.set("redirect_uri", redirectUri);
    params.set("code_verifier", codeVerifier);

    const tokenResp = await fetch("https://accounts.spotify.com/api/token", {
      method: "POST",
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: params.toString(),
    });

    const tokenJson = (await tokenResp.json()) as SpotifyTokenResponse;

    if (!tokenResp.ok) {
      logger.error("Spotify token exchange failed", tokenJson);
      res.status(tokenResp.status).json(tokenJson);
      return;
    }

    const expiresAt = Date.now() + tokenJson.expires_in * 1000;

    await admin
      .firestore()
      .collection("spotifyTokens")
      .doc(uid)
      .set(
        {
          refreshToken: tokenJson.refresh_token ?? null,
          accessToken: tokenJson.access_token ?? null,
          expiresAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

    res.status(200).json({
      accessToken: tokenJson.access_token,
      expiresIn: tokenJson.expires_in,
      tokenType: tokenJson.token_type,
      scope: tokenJson.scope,
    });
  } catch (error) {
    logger.error("spotifyExchange error", error);
    res.status(500).json({error: "Internal server error"});
  }
});

type SpotifyUserProfile = {
  id: string;
  display_name?: string;
  email?: string;
  images?: Array<{ url: string }>;
};

export const spotifyLogin = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const body = (req.body ?? {}) as Record<string, unknown>;
    const code = body["code"];
    const codeVerifier = body["codeVerifier"];
    const redirectUri = body["redirectUri"];

    if (
      typeof code !== "string" ||
        typeof codeVerifier !== "string" ||
        typeof redirectUri !== "string"
    ) {
      res.status(400).json({
        error: "Missing or invalid code, codeVerifier, or redirectUri",
      });
      return;
    }

    const clientId = process.env.SPOTIFY_CLIENT_ID;
    if (!clientId) {
      res.status(500).json({error: "Missing SPOTIFY_CLIENT_ID env var"});
      return;
    }

    // Exchange auth code for Spotify tokens
    const params = new URLSearchParams();
    params.set("client_id", clientId);
    params.set("grant_type", "authorization_code");
    params.set("code", code);
    params.set("redirect_uri", redirectUri);
    params.set("code_verifier", codeVerifier);

    const tokenResp = await fetch("https://accounts.spotify.com/api/token", {
      method: "POST",
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: params.toString(),
    });

    const tokenJson = (await tokenResp.json()) as SpotifyTokenResponse;

    if (!tokenResp.ok) {
      logger.error("Spotify token exchange failed", tokenJson);
      res.status(tokenResp.status).json(tokenJson);
      return;
    }

    // Fetch Spotify user profile
    const profileResp = await fetch("https://api.spotify.com/v1/me", {
      headers: {Authorization: `Bearer ${tokenJson.access_token}`},
    });

    const profile = (await profileResp.json()) as SpotifyUserProfile;

    if (!profileResp.ok) {
      logger.error("Spotify profile fetch failed", profile);
      res.status(profileResp.status).json({
        error: "Failed to fetch Spotify profile",
      });
      return;
    }

    const uid = `spotify:${profile.id}`;
    const expiresAt = Date.now() + tokenJson.expires_in * 1000;

    // Ensure the Firebase user exists
    try {
      await admin.auth().getUser(uid);
    } catch {
      await admin.auth().createUser({uid});
    }

    // Create Firebase custom token
    const customToken = await admin.auth().createCustomToken(uid);

    // Store Spotify tokens
    await admin.firestore().collection("spotifyTokens").doc(uid).set(
      {
        refreshToken: tokenJson.refresh_token ?? null,
        accessToken: tokenJson.access_token ?? null,
        expiresAt,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    // Create/update user profile
    const profileImageUrl = profile.images?.[0]?.url ?? null;
    const displayName = profile.display_name ?? null;
    await admin.firestore().collection("users").doc(uid).set(
      {
        displayName,
        displayNameLower: displayName ? displayName.toLowerCase() : null,
        email: profile.email ?? null,
        profileImageUrl,
        spotifyId: profile.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    res.status(200).json({
      customToken,
      user: {
        displayName: profile.display_name ?? null,
        spotifyId: profile.id,
        profileImageUrl,
      },
    });
  } catch (error) {
    logger.error("spotifyLogin error", error);
    res.status(500).json({error: "Internal server error"});
  }
});

export const spotifyRefresh = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const authHeader = req.header("Authorization") || "";
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) {
      res.status(401).json({error: "Missing Authorization Bearer token"});
      return;
    }

    const idToken = match[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const docRef = admin.firestore().collection("spotifyTokens").doc(uid);
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
      res.status(404).json({error: "No Spotify tokens found for user"});
      return;
    }

    const data = docSnap.data() as { refreshToken?: string };
    const refreshToken = data.refreshToken;
    if (!refreshToken) {
      res.status(400).json({error: "Missing refreshToken for user"});
      return;
    }

    const clientId = process.env.SPOTIFY_CLIENT_ID;
    if (!clientId) {
      res.status(500).json({error: "Missing SPOTIFY_CLIENT_ID env var"});
      return;
    }

    const params = new URLSearchParams();
    params.set("client_id", clientId);
    params.set("grant_type", "refresh_token");
    params.set("refresh_token", refreshToken);

    const tokenResp = await fetch("https://accounts.spotify.com/api/token", {
      method: "POST",
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: params.toString(),
    });

    const tokenJson = (await tokenResp.json()) as SpotifyTokenResponse;

    if (!tokenResp.ok) {
      logger.error("Spotify refresh failed", tokenJson);
      res.status(tokenResp.status).json(tokenJson);
      return;
    }

    const expiresAt = Date.now() + tokenJson.expires_in * 1000;

    await docRef.set(
      {
        accessToken: tokenJson.access_token ?? null,
        expiresAt,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    res.status(200).json({
      accessToken: tokenJson.access_token,
      expiresIn: tokenJson.expires_in,
      tokenType: tokenJson.token_type,
      scope: tokenJson.scope,
    });
  } catch (error) {
    logger.error("spotifyRefresh error", error);
    res.status(500).json({error: "Internal server error"});
  }
});

export const spotifySearch = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const authHeader = req.header("Authorization") || "";
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) {
      res.status(401).json({error: "Missing Authorization Bearer token"});
      return;
    }

    const idToken = match[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const body = (req.body ?? {}) as Record<string, unknown>;
    const q = body["q"];
    const type = body["type"] ?? "album,track";
    const limit = body["limit"] ?? 10;

    if (typeof q !== "string" || q.trim().length === 0) {
      res.status(400).json({error: "Missing q"});
      return;
    }

    if (typeof type !== "string") {
      res.status(400).json({error: "Invalid type"});
      return;
    }

    if (typeof limit !== "number") {
      res.status(400).json({error: "Invalid limit"});
      return;
    }

    const accessToken = await getSpotifyAccessToken(uid);

    // Call Spotify search API
    const url = new URL("https://api.spotify.com/v1/search");
    url.searchParams.set("q", q);
    url.searchParams.set("type", type);
    url.searchParams.set("limit", String(limit));

    const searchResp = await fetch(url.toString(), {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    const searchJson = await searchResp.json();

    if (!searchResp.ok) {
      res.status(searchResp.status).json(searchJson);
      return;
    }

    res.status(200).json(searchJson);
  } catch (error: unknown) {
    const err = error as {
      status?: number; message?: string; body?: unknown;
    };
    logger.error("spotifySearch error", error);
    const code = err.status || 500;
    const body = err.body ||
      {error: err.message || "Internal server error"};
    res.status(code).json(body);
  }
});

export const spotifyAlbumTracks = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const authHeader = req.header("Authorization") || "";
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) {
      res.status(401).json({error: "Missing Authorization Bearer token"});
      return;
    }

    const idToken = match[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const body = (req.body ?? {}) as Record<string, unknown>;
    const albumId = body["albumId"];

    if (typeof albumId !== "string" || albumId.trim().length === 0) {
      res.status(400).json({error: "Missing albumId"});
      return;
    }

    const accessToken = await getSpotifyAccessToken(uid);

    // Call Spotify album API
    const albumResp = await fetch(
      `https://api.spotify.com/v1/albums/${encodeURIComponent(albumId)}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      }
    );

    const albumJson = await albumResp.json();

    if (!albumResp.ok) {
      res.status(albumResp.status).json(albumJson);
      return;
    }

    res.status(200).json(albumJson);
  } catch (error: unknown) {
    const err = error as {
      status?: number; message?: string; body?: unknown;
    };
    logger.error("spotifyAlbumTracks error", error);
    const code = err.status || 500;
    const body = err.body ||
      {error: err.message || "Internal server error"};
    res.status(code).json(body);
  }
});

export const recentlyPlayed = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const authHeader = req.header("Authorization") || "";
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) {
      res.status(401).json({error: "Missing Authorization Bearer token"});
      return;
    }

    const idToken = match[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const accessToken = await getSpotifyAccessToken(uid);

    const recentResp = await fetch(
      "https://api.spotify.com/v1/me/player/recently-played?limit=10",
      {headers: {Authorization: `Bearer ${accessToken}`}}
    );

    type RecentItem = {
      track: {
        id: string;
        name: string;
        artists: Array<{ name: string }>;
        album: {
          id: string;
          name: string;
          album_type: string;
          images: Array<{ url: string }>;
          total_tracks: number;
        };
      };
    };

    const recentJson = await recentResp.json() as { items?: RecentItem[] };

    if (!recentResp.ok) {
      res.status(recentResp.status).json(recentJson);
      return;
    }

    const items = recentJson.items ?? [];

    // Deduplicate by track ID, preserving recency order
    const seen = new Set<string>();
    const uniqueTracks = items
      .filter((item) => {
        if (seen.has(item.track.id)) return false;
        seen.add(item.track.id);
        return true;
      })
      .map((item) => item.track);

    if (uniqueTracks.length === 0) {
      res.status(200).json({tracks: []});
      return;
    }

    const trackIds = uniqueTracks.map((t) => t.id);

    // Check which tracks this user has already rated (single Firestore query)
    const snapshot = await admin.firestore()
      .collection("reviews")
      .where("userId", "==", uid)
      .where("trackId", "in", trackIds)
      .get();

    const ratedIds = new Set(
      snapshot.docs.map((d) => d.data().trackId as string)
    );

    const unratedTracks = uniqueTracks
      .filter((t) => !ratedIds.has(t.id))
      .map((t) => {
        const images = t.album.images;
        return {
          id: t.id,
          name: t.name,
          artistName: t.artists.map((a) => a.name).join(", "),
          albumName: t.album.name,
          albumId: t.album.id,
          albumType: t.album.album_type,
          imageUrl: images[images.length - 1]?.url ?? null,
          largeImageUrl: images[0]?.url ?? null,
          albumTrackCount: t.album.total_tracks,
        };
      });

    res.status(200).json({tracks: unratedTracks});
  } catch (error: unknown) {
    const err = error as {status?: number; message?: string; body?: unknown};
    logger.error("recentlyPlayed error", error);
    const code = err.status || 500;
    const body = err.body || {error: err.message || "Internal server error"};
    res.status(code).json(body);
  }
});

export const spotifyArtistAlbums = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const authHeader = req.header("Authorization") || "";
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) {
      res.status(401).json({error: "Missing Authorization Bearer token"});
      return;
    }

    const idToken = match[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const body = (req.body ?? {}) as Record<string, unknown>;
    const artistId = body["artistId"];

    if (typeof artistId !== "string" || artistId.trim().length === 0) {
      res.status(400).json({error: "Missing artistId"});
      return;
    }

    // Only append offset/limit when non-default. Spotify returns 400
    // "Invalid limit" when offset=0 is sent explicitly alongside limit.
    const reqOffset =
      typeof body["offset"] === "number" ?
        (body["offset"] as number) : 0;
    const reqLimit =
      typeof body["limit"] === "number" ?
        Math.min(body["limit"] as number, 50) : null;

    const accessToken = await getSpotifyAccessToken(uid);

    const base =
      `https://api.spotify.com/v1/artists/${encodeURIComponent(artistId)}`;
    let albumsUrl =
      `${base}/albums?include_groups=album,single,compilation`;
    if (reqOffset > 0) albumsUrl += `&offset=${reqOffset}`;
    if (reqLimit !== null) albumsUrl += `&limit=${reqLimit}`;

    const [artistResp, albumsResp] = await Promise.all([
      fetch(
        `${base}`,
        {headers: {Authorization: `Bearer ${accessToken}`}}
      ),
      fetch(albumsUrl, {
        headers: {Authorization: `Bearer ${accessToken}`},
      }),
    ]);

    const artistText = await artistResp.text();
    const albumsText = await albumsResp.text();

    // Spotify may return plain text (e.g. "Too many requests") on errors,
    // so parse safely rather than calling .json() directly.
    const safeJson = (text: string): unknown => {
      try {
        return JSON.parse(text);
      } catch {
        return {error: text};
      }
    };
    const artistJson = safeJson(artistText);
    const albumsJson = safeJson(albumsText);

    if (!artistResp.ok) {
      logger.error("Spotify artist fetch failed", {
        status: artistResp.status,
        body: artistJson,
      });
      res.status(artistResp.status).json({
        source: "artist",
        spotifyError: artistJson,
      });
      return;
    }

    if (!albumsResp.ok) {
      logger.error("Spotify albums fetch failed", {
        url: albumsUrl,
        status: albumsResp.status,
        body: albumsJson,
      });
      res.status(albumsResp.status).json({
        source: "albums",
        url: albumsUrl,
        spotifyError: albumsJson,
      });
      return;
    }

    res.status(200).json({artist: artistJson, albums: albumsJson});
  } catch (error: unknown) {
    const err = error as {
      status?: number; message?: string; body?: unknown;
    };
    logger.error("spotifyArtistAlbums error", error);
    const code = err.status || 500;
    const body = err.body ||
      {error: err.message || "Internal server error"};
    res.status(code).json(body);
  }
});
