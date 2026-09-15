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

interface InstructorStatsChartProps {
  degrees: Array<{ degree: string; count: number }>;
  contracts: Array<{ contract_type: string; count: number }>;
}

export default function InstructorStatsChart({ degrees, contracts }: InstructorStatsChartProps) {
  const degreeLabels = degrees.map((d) => d.degree || 'Chưa cập nhật');
  const degreeCounts = degrees.map((d) => Number(d.count || 0));
  const totalInstructors = degreeCounts.reduce((acc, curr) => acc + curr, 0);

  const colors = ['#6366f1', '#ec4899', '#3b82f6', '#14b8a6', '#f97316'];
  const hoverColors = ['#4f46e5', '#db2777', '#2563eb', '#0d9488', '#ea580c'];

  const chartData = {
    labels: degreeLabels.length > 0 ? degreeLabels : ['Chưa có dữ liệu'],
    datasets: [
      {
        data: degreeCounts.length > 0 ? degreeCounts : [1],
        backgroundColor: colors.slice(0, Math.max(degreeLabels.length, 1)),
        hoverBackgroundColor: hoverColors.slice(0, Math.max(degreeLabels.length, 1)),
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
          padding: 10,
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
            const count = context.raw;
            return ` ${count} Giảng viên`;
          },
        },
      },
    },
  };

  return (
    <div className="w-full flex flex-col items-center">
      <div className="relative w-full h-[220px]">
        <Doughnut data={chartData} options={options} />
        {/* Center overlay total text */}
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center pb-6">
          <span className="text-[10px] font-semibold text-gray-400 uppercase tracking-wider">Tổng GV</span>
          <span className="text-xl font-bold text-gray-900 dark:text-white">{totalInstructors}</span>
        </div>
      </div>

      {/* Contract type badges underneath */}
      <div className="mt-3 grid grid-cols-2 gap-2 border-t border-gray-100 pt-3 dark:border-gray-800 w-full">
        {contracts.map((c) => (
          <div
            key={c.contract_type}
            className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2 dark:bg-gray-800/60"
          >
            <span className="text-xs text-gray-500 dark:text-gray-400">
              {c.contract_type === 'FULLTIME' ? 'Toàn thời gian' : 'Thỉnh giảng'}
            </span>
            <span className="text-xs font-bold text-gray-900 dark:text-white">
              {c.count} GV
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
