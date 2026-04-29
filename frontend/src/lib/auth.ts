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
const ACCESS_TOKEN_KEY = "accessToken";
const REFRESH_TOKEN_KEY = "refreshToken";
const ACCOUNT_KEY = "account";

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
    window.localStorage.setItem(ACCESS_TOKEN_KEY, authorization.replace("Bearer ", ""));
  }
  if (data.refresh_token) {
    window.localStorage.setItem(REFRESH_TOKEN_KEY, data.refresh_token);
  }
  if (data.account) {
    window.localStorage.setItem(ACCOUNT_KEY, JSON.stringify(data.account));
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

export function getCurrentAccount() {
  const stored = window.localStorage.getItem(ACCOUNT_KEY);
  if (!stored) return null;

  try {
    return JSON.parse(stored) as NonNullable<AuthResponse["account"]>;
  } catch {
    return null;
  }
}

export function hasAccessToken() {
  return Boolean(window.localStorage.getItem(ACCESS_TOKEN_KEY));
}

export function logout() {
  window.localStorage.removeItem(ACCESS_TOKEN_KEY);
  window.localStorage.removeItem(REFRESH_TOKEN_KEY);
  window.localStorage.removeItem(ACCOUNT_KEY);
}
