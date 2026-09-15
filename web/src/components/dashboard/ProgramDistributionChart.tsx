'use client';

import React from 'react';
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend,
} from 'chart.js';
import { Doughnut } from 'react-chartjs-2';

ChartJS.register(ArcElement, Tooltip, Legend);

interface ProgramDistributionChartProps {
  data: Array<{
    program_id: string;
    program_name: string;
    student_count: number;
    total_revenue: number;
  }>;
}

export default function ProgramDistributionChart({ data }: ProgramDistributionChartProps) {
  const labels = data.map((d) => d.program_name);
  const studentCounts = data.map((d) => Number(d.student_count || 0));
  const totalStudents = studentCounts.reduce((acc, curr) => acc + curr, 0);

  const colors = ['#465fff', '#8b5cf6', '#06b6d4', '#f59e0b', '#10b981'];
  const hoverColors = ['#3641f5', '#7c3aed', '#0891b2', '#d97706', '#059669'];

  const chartData = {
    labels: labels.length > 0 ? labels : ['Chưa có dữ liệu'],
    datasets: [
      {
        data: studentCounts.length > 0 ? studentCounts : [1],
        backgroundColor: colors.slice(0, Math.max(labels.length, 1)),
        hoverBackgroundColor: hoverColors.slice(0, Math.max(labels.length, 1)),
        borderWidth: 2,
        borderColor: '#ffffff',
        cutout: '72%',
      },
    ],
  };

  const options: any = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'bottom' as const,
        labels: {
          usePointStyle: true,
          pointStyle: 'circle',
          boxWidth: 8,
          boxHeight: 8,
          padding: 12,
          font: {
            family: 'Inter, sans-serif',
            size: 11,
            weight: '500',
          },
          color: '#4b5563',
        },
      },
      tooltip: {
        backgroundColor: '#1f2937',
        titleFont: { family: 'Inter, sans-serif', size: 12, weight: 'bold' },
        bodyFont: { family: 'Inter, sans-serif', size: 12 },
        padding: 12,
        cornerRadius: 8,
        callbacks: {
          label: function (context: any) {
            const idx = context.dataIndex;
            const count = context.raw;
            const rev = data[idx]?.total_revenue || 0;
            return ` ${count} Học viên (${Number(rev).toLocaleString('vi-VN')} VNĐ)`;
          },
        },
      },
    },
  };

  return (
    <div className="w-full flex flex-col items-center">
      <div className="relative w-full h-[280px]">
        <Doughnut data={chartData} options={options} />
        {/* Center overlay total text */}
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center pb-8">
          <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider">Tổng HV</span>
          <span className="text-2xl font-bold text-gray-900 dark:text-white">{totalStudents}</span>
        </div>
      </div>
    </div>
  );
}
