"use client";

import { useEffect, useState } from "react";
import { getCurrentSession } from "@/lib/auth";

type Account = {
  id: number;
  email: string;
};

type AuthSnapshot = {
  account: Account | null;
  isAuthenticated: boolean;
  isCheckingAuth: boolean;
};

export function useAuthSnapshot(): AuthSnapshot {
  const [auth, setAuth] = useState<AuthSnapshot>({
    account: null,
    isAuthenticated: false,
    isCheckingAuth: true,
  });

  useEffect(() => {
    let active = true;

    void getCurrentSession()
      .then((session) => {
        if (!active) return;

        setAuth({
          account: session.account ?? null,
          isAuthenticated: session.isAuthenticated,
          isCheckingAuth: false,
        });
      })
      .catch(() => {
        if (!active) return;

        setAuth({
          account: null,
          isAuthenticated: false,
          isCheckingAuth: false,
        });
      });

    return () => {
      active = false;
    };
  }, []);

  return auth;
}
