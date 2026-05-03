import "server-only";

import type { NextRequest, NextResponse } from "next/server";

export type BffAuthResponse = {
  account?: {
    id: number;
    email: string;
  };
  refresh_token?: string;
  errors?: string[];
  error?: string;
};

export const ACCESS_TOKEN_COOKIE = "communityHubAccessToken";
export const REFRESH_TOKEN_COOKIE = "communityHubRefreshToken";
export const ACCOUNT_COOKIE = "communityHubAccount";
export const DEVICE_ID_COOKIE = "communityHubDeviceId";

const BACKEND_ORIGIN = process.env.BACKEND_ORIGIN || "http://backend:3000";
const ACCESS_TOKEN_MAX_AGE = 60 * 60;
const REFRESH_TOKEN_MAX_AGE = 60 * 60 * 24 * 90;

const cookieOptions = {
  httpOnly: true,
  path: "/",
  sameSite: "lax" as const,
  secure: process.env.NODE_ENV === "production",
};

export function getBackendUrl(path: string) {
  return `${BACKEND_ORIGIN}${path}`;
}

export function getDeviceId(request: NextRequest) {
  return request.cookies.get(DEVICE_ID_COOKIE)?.value || crypto.randomUUID();
}

export function extractBearerToken(response: Response) {
  return response.headers.get("Authorization")?.replace(/^Bearer\s+/i, "") || "";
}

export function getAccountFromRequest(request: NextRequest) {
  const stored = request.cookies.get(ACCOUNT_COOKIE)?.value;
  if (!stored) return null;

  try {
    return JSON.parse(decodeURIComponent(stored)) as NonNullable<BffAuthResponse["account"]>;
  } catch {
    return null;
  }
}

export function setAuthCookies(
  response: NextResponse,
  {
    accessToken,
    refreshToken,
    account,
    deviceId,
  }: {
    accessToken: string;
    refreshToken?: string;
    account?: BffAuthResponse["account"];
    deviceId: string;
  }
) {
  response.cookies.set(ACCESS_TOKEN_COOKIE, accessToken, {
    ...cookieOptions,
    maxAge: ACCESS_TOKEN_MAX_AGE,
  });
  response.cookies.set(DEVICE_ID_COOKIE, deviceId, {
    ...cookieOptions,
    maxAge: REFRESH_TOKEN_MAX_AGE,
  });

  if (refreshToken) {
    response.cookies.set(REFRESH_TOKEN_COOKIE, refreshToken, {
      ...cookieOptions,
      maxAge: REFRESH_TOKEN_MAX_AGE,
    });
  }

  if (account) {
    response.cookies.set(ACCOUNT_COOKIE, encodeURIComponent(JSON.stringify(account)), {
      ...cookieOptions,
      maxAge: REFRESH_TOKEN_MAX_AGE,
    });
  }
}

export function clearAuthCookies(response: NextResponse) {
  response.cookies.delete(ACCESS_TOKEN_COOKIE);
  response.cookies.delete(REFRESH_TOKEN_COOKIE);
  response.cookies.delete(ACCOUNT_COOKIE);
  response.cookies.delete(DEVICE_ID_COOKIE);
}

export function getRefreshToken(request: NextRequest) {
  return request.cookies.get(REFRESH_TOKEN_COOKIE)?.value || "";
}

export function getAccessToken(request: NextRequest) {
  return request.cookies.get(ACCESS_TOKEN_COOKIE)?.value || "";
}

export async function refreshAuthSession(request: NextRequest) {
  const refreshToken = getRefreshToken(request);
  if (!refreshToken) return null;

  const response = await fetch(getBackendUrl("/api/v1/auth/refresh"), {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ refresh_token: refreshToken }),
  });
  const data = (await response.json().catch(() => ({}))) as BffAuthResponse;

  if (!response.ok) return null;

  const accessToken = extractBearerToken(response);
  if (!accessToken) return null;

  return {
    accessToken,
    refreshToken: data.refresh_token,
    account: data.account,
    deviceId: getDeviceId(request),
  };
}
