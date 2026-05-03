import { NextRequest, NextResponse } from "next/server";
import {
  clearAuthCookies,
  getAccessToken,
  getBackendUrl,
  getRefreshToken,
  refreshAuthSession,
  setAuthCookies,
} from "@/lib/serverAuth";

type UserRouteContext = {
  params: Promise<{
    path: string[];
  }>;
};

async function proxyUserApi(request: NextRequest, context: UserRouteContext) {
  let accessToken = getAccessToken(request);
  let refreshed = accessToken ? null : await refreshAuthSession(request);

  if (refreshed) {
    accessToken = refreshed.accessToken;
  }

  if (!accessToken) {
    const response = NextResponse.json({ error: "認証が必要です" }, { status: 401 });

    if (getRefreshToken(request)) {
      clearAuthCookies(response);
    }

    return response;
  }

  const { path } = await context.params;
  const backendPath = `/api/v1/user/${path.join("/")}${request.nextUrl.search}`;
  const headers: Record<string, string> = {
    Accept: request.headers.get("Accept") || "application/json",
    Authorization: `Bearer ${accessToken}`,
  };

  const contentType = request.headers.get("Content-Type");
  if (contentType) {
    headers["Content-Type"] = contentType;
  }

  const requestBody = ["GET", "HEAD"].includes(request.method)
    ? undefined
    : await request.text();
  let response = await fetch(getBackendUrl(backendPath), {
    method: request.method,
    headers,
    body: requestBody,
  });

  if (response.status === 401 && !refreshed) {
    refreshed = await refreshAuthSession(request);

    if (refreshed) {
      accessToken = refreshed.accessToken;
      headers.Authorization = `Bearer ${accessToken}`;
      response = await fetch(getBackendUrl(backendPath), {
        method: request.method,
        headers,
        body: requestBody,
      });
    }
  }

  const body = await response.text();
  const nextResponse = new NextResponse(body, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("Content-Type") || "application/json",
    },
  });

  if (refreshed) {
    setAuthCookies(nextResponse, refreshed);
  } else if (response.status === 401 && getRefreshToken(request)) {
    clearAuthCookies(nextResponse);
  }

  return nextResponse;
}

export function GET(request: NextRequest, context: UserRouteContext) {
  return proxyUserApi(request, context);
}

export function POST(request: NextRequest, context: UserRouteContext) {
  return proxyUserApi(request, context);
}

export function DELETE(request: NextRequest, context: UserRouteContext) {
  return proxyUserApi(request, context);
}
