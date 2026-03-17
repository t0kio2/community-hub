export const api = async <T>(
  path: string,
  options: RequestInit = {},
): Promise<T> => {
  const apiOrigin =
    typeof window === 'undefined'
      ? process.env.API_ORIGIN ||
        (import.meta as any).env?.VITE_API_ORIGIN ||
        'http://api:3000'
      : '';

  const defaultOptions: RequestInit = {
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...options.headers,
    },
    ...options,
  };

  const res = await fetch(`${apiOrigin}${path}`, defaultOptions);

  if (!res.ok) {
    throw new Error(`HTTP error ${res.status}: ${res.statusText}`);
  }

  // No Content
  if (res.status === 204) {
    return Promise.resolve({} as T);
  }

  return res.json() as Promise<T>;
};
