export type AuthResponse = {
  account?: {
    id: number;
    email: string;
  };
  refresh_token?: string;
  errors?: string[];
  error?: string;
};

type AuthParams = {
  email: string;
  password: string;
  passwordConfirmation?: string;
};

const DEVICE_ID_KEY = "communityHubDeviceId";

function getDeviceId() {
  const current = window.localStorage.getItem(DEVICE_ID_KEY);
  if (current) return current;

  const next = window.crypto.randomUUID();
  window.localStorage.setItem(DEVICE_ID_KEY, next);
  return next;
}

async function requestAuth(path: string, body: unknown) {
  const response = await fetch(path, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Device-Id": getDeviceId(),
      "X-Device-Name": "browser",
    },
    body: JSON.stringify(body),
  });

  const data = (await response.json().catch(() => ({}))) as AuthResponse;

  if (!response.ok) {
    throw new Error(data.errors?.join("\n") || data.error || "認証に失敗しました");
  }

  const authorization = response.headers.get("Authorization");
  if (authorization) {
    window.localStorage.setItem("accessToken", authorization.replace("Bearer ", ""));
  }
  if (data.refresh_token) {
    window.localStorage.setItem("refreshToken", data.refresh_token);
  }

  return data;
}

export function login({ email, password }: AuthParams) {
  return requestAuth("/api/v1/auth/sign_in", {
    user_account: {
      email,
      password,
    },
  });
}

export function signUp({ email, password, passwordConfirmation }: AuthParams) {
  return requestAuth("/api/v1/auth", {
    user_account: {
      email,
      password,
      password_confirmation: passwordConfirmation,
    },
  });
}
