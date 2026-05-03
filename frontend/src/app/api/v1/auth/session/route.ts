import { NextRequest, NextResponse } from "next/server";
import {
  clearAuthCookies,
  getAccessToken,
  getAccountFromRequest,
  getBackendUrl,
  getRefreshToken,
  refreshAuthSession,
  setAuthCookies,
} from "@/lib/serverAuth";

export async function GET(request: NextRequest) {
  let account = getAccountFromRequest(request);
  let accessToken = getAccessToken(request);
  const refreshed = accessToken ? null : await refreshAuthSession(request);

  if (refreshed) {
    account = refreshed.account ?? account;
    accessToken = refreshed.accessToken;
  }

  const response = NextResponse.json({
    account,
    isAuthenticated: Boolean(accessToken),
  });

  if (refreshed) {
    setAuthCookies(response, refreshed);
  } else if (!accessToken && getRefreshToken(request)) {
    clearAuthCookies(response);
  }

  return response;
}

export async function DELETE(request: NextRequest) {
  const refreshToken = getRefreshToken(request);

  if (refreshToken) {
    await fetch(getBackendUrl("/api/v1/auth/refresh"), {
      method: "DELETE",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
    }).catch(() => null);
  }

  const response = NextResponse.json({}, { status: 200 });
  clearAuthCookies(response);

  return response;
}
