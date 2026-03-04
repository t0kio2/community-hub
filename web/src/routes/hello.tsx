import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/hello')({ component: Hello })

function Hello() {
  return (
    <main className="page-wrap px-4 pb-8 pt-14">
      <h1 className="display-title text-4xl font-bold text-[var(--sea-ink)]">
        Hello world
      </h1>
    </main>
  )
}

