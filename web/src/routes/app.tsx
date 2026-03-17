import * as React from 'react'
import { createFileRoute, Link } from '@tanstack/react-router'

export const Route = createFileRoute('/app')({
  component: AppHome,
})

function AppHome() {
  return (
    <main>
      <h1>App</h1>
      <p>ログイン後のホームです。</p>
      <ul>
        <li>
          <Link to="/app/profile">プロフィールを見る</Link>
        </li>
      </ul>
    </main>
  )
}

