import { createFileRoute } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';

type HelloResponse = { message: string; method: string };

const helloQuery = () => ({
  queryKey: ['hello'] as const,
  queryFn: () => api<HelloResponse>('/api/v1/hello'),
});

export const Route = createFileRoute('/hello')({
  loader: async ({ context }: { context: any }) => {
    await context.queryClient.ensureQueryData(helloQuery());
    return null;
  },
  component: Hello,
});

function Hello() {
  const { data, isPending, error } = useQuery(helloQuery());

  return (
    <main>
      <h1>Hello (from API)</h1>
      {isPending && <p>Loading...</p>}
      {error && <p style={{ color: 'crimson' }}>Error: {(error as Error).message}</p>}
      {!isPending && !error && <p>{data?.message}</p>}
    </main>
  );
}
