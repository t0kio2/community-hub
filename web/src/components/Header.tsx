import { Link, useNavigate } from '@tanstack/react-router';
import { useAuth } from '@/contexts/AuthContext';
import * as React from 'react';

export default function Header() {
  const { isAuthenticated, logout, user } = useAuth();
  const navigate = useNavigate();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const handleLogout = async () => {
    try {
      await logout();
      // Redirect to home page after logout
      navigate({ to: '/' });
    } catch (error) {
      console.error('Failed to logout:', error);
      // Handle logout error if needed
    }
  };

  return (
    <header>
      <nav>
        <h2>
          <Link to="/">App</Link>
        </h2>
        <div className="links">
          <a href="/openapi.yaml">OpenAPI</a>
          <Link to="/about">About</Link>
          <Link to="/hello">Hello</Link>
          <Link to="/">Home</Link>
          {!mounted ? null : isAuthenticated ? (
            <>
              <span style={{ margin: '0 10px' }}>Hi, {user?.email}</span>
              <button
                onClick={handleLogout}
                style={{
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  textDecoration: 'underline',
                }}
              >
                Logout
              </button>
            </>
          ) : (
            <>
              <Link to="/auth/user/login">Login</Link>
              <Link to="/auth/user/sign-up">Sign Up</Link>
            </>
          )}
        </div>
      </nav>
    </header>
  );
}
