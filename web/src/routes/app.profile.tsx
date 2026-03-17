import { createFileRoute } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';

type Me = {
  id: number;
  email: string;
  role: 'user' | 'tenant' | 'admin';
  status: 'active' | 'suspended';
  created_at?: string;
  updated_at?: string;
};

export const Route = createFileRoute('/app/profile')({
  component: Profile,
});

function Profile() {
  const { token } = useAuth();

  const meQuery = useQuery({
    queryKey: ['me'],
    queryFn: async () =>
      api<Me>('/api/v1/me', {
        headers: token ? { Authorization: `Bearer ${token}` } : undefined,
      }),
  });

  return (
    <main>
      <h1>Profile</h1>
      {meQuery.isPending && <p>読み込み中...</p>}
      {meQuery.error && (
        <p style={{ color: 'crimson' }}>エラー: {(meQuery.error as Error).message}</p>
      )}
      {meQuery.data && (
        <div style={{ lineHeight: 1.8 }}>
          <div>
            <strong>ID:</strong> {meQuery.data.id}
          </div>
          <div>
            <strong>Email:</strong> {meQuery.data.email}
          </div>
          <div>
            <strong>Role:</strong> {meQuery.data.role}
          </div>
          <div>
            <strong>Status:</strong> {meQuery.data.status}
          </div>
          {meQuery.data.created_at && (
            <div>
              <strong>Created:</strong> {new Date(meQuery.data.created_at).toISOString()}
            </div>
          )}
          {meQuery.data.updated_at && (
            <div>
              <strong>Updated:</strong> {new Date(meQuery.data.updated_at).toISOString()}
            </div>
          )}
        </div>
      )}
    </main>
  );
}
