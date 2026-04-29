import * as React from 'react';
import { api } from '@/lib/api';

// Assuming User model has at least these properties based on typical devise setup
type User = {
  id: number;
  email: string;
  created_at: string;
  updated_at: string;
};

type AuthContextType = {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  register: (
    email: string,
    password: string,
    passwordConfirmation: string,
  ) => Promise<User>;
};

const AuthContext = React.createContext<AuthContextType | undefined>(undefined);

// Custom hook to use the auth context
export const useAuth = () => {
  const context = React.useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

type AuthProviderProps = {
  children: React.ReactNode;
};

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const [user, setUser] = React.useState<User | null>(null);
  const [token, setToken] = React.useState<string | null>(() => {
    if (typeof window === 'undefined') {
      return null;
    }
    return localStorage.getItem('authToken');
  });

  const fetchAndSetUser = React.useCallback(
    async (authToken: string, userId: number) => {
      try {
        const userData = await api<User>(`/api/v1/users/${userId}`, {
          headers: { Authorization: `Bearer ${authToken}` },
        });
        setUser(userData);
      } catch (error) {
        console.error('Failed to fetch user:', error);
        // Token might be invalid, so log out
        await logout();
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );

  React.useEffect(() => {
    if (token) {
      // Basic token validation and user fetching
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
        // Check if token is expired
        if (payload.exp * 1000 > Date.now()) {
          fetchAndSetUser(token, payload.sub);
        } else {
          // Token expired
          setToken(null);
          localStorage.removeItem('authToken');
          setUser(null);
        }
      } catch (e) {
        console.error('Invalid token found:', e);
        setToken(null);
        localStorage.removeItem('authToken');
        setUser(null);
      }
    }
  }, [token, fetchAndSetUser]);

  const login = async (email: string, password: string) => {
    const apiOrigin =
      typeof window === 'undefined'
        ? process.env.API_ORIGIN ||
          (import.meta as any).env?.VITE_API_ORIGIN ||
          'http://backend:3000'
        : '';
    const response = await fetch(`${apiOrigin}/api/v1/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ user: { email, password } }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || 'Login failed');
    }

    const authHeader = response.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('No token received');
    }

    const new_token = authHeader.replace('Bearer ', '');
    localStorage.setItem('authToken', new_token);
    setToken(new_token);

    // ログイン応答の形式は { user: { id, email } }
    // フル情報は /api/users/:id から取得する
    const data = await response.json();
    const userId = (data as any)?.user?.id;
    if (typeof userId !== 'number') {
      // JWT の sub からフォールバック（形式: Bearer JWT）
      try {
        const payload = JSON.parse(atob(new_token.split('.')[1]));
        await fetchAndSetUser(new_token, payload.sub);
        return;
      } catch (e) {
        throw new Error('Invalid login response');
      }
    }
    await fetchAndSetUser(new_token, userId);
  };

  const logout = async () => {
    if (token) {
      await api('/api/v1/auth/logout', {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
    }
    localStorage.removeItem('authToken');
    setToken(null);
    setUser(null);
  };

  const register = async (
    email: string,
    password: string,
    passwordConfirmation: string,
  ) => {
    const response = await api<User>('/api/v1/auth/signup', {
      method: 'POST',
      body: JSON.stringify({
        user: { email, password, password_confirmation: passwordConfirmation },
      }),
    });
    return response;
  };

  const authContextValue = {
    user,
    token,
    isAuthenticated: !!token,
    login,
    logout,
    register,
  };

  return (
    <AuthContext.Provider value={authContextValue}>
      {children}
    </AuthContext.Provider>
  );
};
