import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Community Hub",
  description: "Community Hub",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  );
}
