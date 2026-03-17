import { Link, useNavigate } from '@tanstack/react-router';
import { useAuth } from '@/contexts/AuthContext';

export default function Header() {
  const { isAuthenticated, logout, user } = useAuth();
  const navigate = useNavigate();

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
          {isAuthenticated ? (
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
              <Link to="/login">Login</Link>
              <Link to="/register">Register</Link>
            </>
          )}
        </div>
      </nav>
    </header>
  );
}
