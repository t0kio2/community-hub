import { NextRequest, NextResponse } from "next/server";
import {
  extractBearerToken,
  getBackendUrl,
  getDeviceId,
  setAuthCookies,
  type BffAuthResponse,
} from "@/lib/serverAuth";

export async function POST(request: NextRequest) {
  const deviceId = getDeviceId(request);
  const response = await fetch(getBackendUrl("/api/v1/auth"), {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Device-Id": deviceId,
      "X-Device-Name": "browser",
    },
    body: await request.text(),
  });
  const data = (await response.json().catch(() => ({}))) as BffAuthResponse;

  if (!response.ok) {
    return NextResponse.json(data, { status: response.status });
  }

  const accessToken = extractBearerToken(response);
  if (!accessToken) {
    return NextResponse.json({ error: "アクセストークンを取得できませんでした" }, { status: 502 });
  }

  const nextResponse = NextResponse.json({ account: data.account }, { status: response.status });
  setAuthCookies(nextResponse, {
    accessToken,
    refreshToken: data.refresh_token,
    account: data.account,
    deviceId,
  });

  return nextResponse;
}
