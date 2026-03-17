import { useState } from 'react';
import * as React from 'react';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { useAuth } from '@/contexts/AuthContext';

export const Route = createFileRoute('/register')({
  component: RegisterComponent,
});

function RegisterComponent() {
  const navigate = useNavigate({ from: '/register' });
  const { register } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirmation, setShowPasswordConfirmation] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (password !== passwordConfirmation) {
      setError('Passwords do not match.');
      return;
    }
    setError(null);
    setSuccess(null);
    setIsSubmitting(true);
    try {
      await register(email, password, passwordConfirmation);
      setSuccess('Registration successful! Please log in.');
      setTimeout(() => {
        navigate({ to: '/login' });
      }, 2000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      style={{
        maxWidth: '400px',
        margin: '40px auto',
        padding: '20px',
        border: '1px solid #ccc',
        borderRadius: '8px',
      }}
    >
      <h2>Register</h2>
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: '15px' }}>
          <label htmlFor="email" style={{ display: 'block', marginBottom: '5px' }}>
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            style={{ width: '100%', padding: '8px', boxSizing: 'border-box' }}
          />
        </div>
        <div style={{ marginBottom: '15px' }}>
          <label htmlFor="password" style={{ display: 'block', marginBottom: '5px' }}>
            Password
          </label>
          <div style={{ display: 'flex', gap: '8px' }}>
            <input
              id="password"
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              style={{ flex: 1, padding: '8px', boxSizing: 'border-box' }}
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              aria-pressed={showPassword}
              aria-label={showPassword ? 'Hide password' : 'Show password'}
              style={{ padding: '8px 12px', cursor: 'pointer' }}
            >
              {showPassword ? 'Hide' : 'Show'}
            </button>
          </div>
        </div>
        <div style={{ marginBottom: '15px' }}>
          <label htmlFor="passwordConfirmation" style={{ display: 'block', marginBottom: '5px' }}>
            Confirm Password
          </label>
          <div style={{ display: 'flex', gap: '8px' }}>
            <input
              id="passwordConfirmation"
              type={showPasswordConfirmation ? 'text' : 'password'}
              value={passwordConfirmation}
              onChange={(e) => setPasswordConfirmation(e.target.value)}
              required
              style={{ flex: 1, padding: '8px', boxSizing: 'border-box' }}
            />
            <button
              type="button"
              onClick={() => setShowPasswordConfirmation((v) => !v)}
              aria-pressed={showPasswordConfirmation}
              aria-label={showPasswordConfirmation ? 'Hide confirm password' : 'Show confirm password'}
              style={{ padding: '8px 12px', cursor: 'pointer' }}
            >
              {showPasswordConfirmation ? 'Hide' : 'Show'}
            </button>
          </div>
        </div>
        {error && <p style={{ color: 'crimson', marginBottom: '10px' }}>{error}</p>}
        {success && <p style={{ color: 'green', marginBottom: '10px' }}>{success}</p>}
        <button
          type="submit"
          disabled={isSubmitting}
          style={{ width: '100%', padding: '10px', cursor: 'pointer' }}
        >
          {isSubmitting ? 'Registering...' : 'Register'}
        </button>
      </form>
    </div>
  );
}
