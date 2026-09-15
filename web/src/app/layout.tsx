import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import "flatpickr/dist/flatpickr.css";
import { SidebarProvider } from '@/context/SidebarContext';
import { ThemeProvider } from '@/context/ThemeContext';

export const metadata: Metadata = {
  title: 'PTIT Training | Hệ CSDL Quản Lý Trung Tâm Đào Tạo',
  description: 'Hệ thống CSDL Quản lý đào tạo, phân công giảng dạy, lịch học và kết quả thi',
};

const inter = Inter({
  subsets: ["latin", "vietnamese"],
  display: "swap",
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi">
      <body className={`${inter.className} dark:bg-gray-900`}>
        <ThemeProvider>
          <SidebarProvider>{children}</SidebarProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
