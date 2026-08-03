import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "NexClin",
  description: "Plataforma operacional inteligente para clínicas",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
