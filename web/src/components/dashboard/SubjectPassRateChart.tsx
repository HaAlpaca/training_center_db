'use client';

import React from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Bar } from 'react-chartjs-2';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

interface SubjectPassRateChartProps {
  data: Array<{
    subject_id: string;
    subject_name: string;
    class_name: string;
    total_candidates: number;
    passed_count: number;
    failed_count: number;
    pass_rate_percent: number;
  }>;
}

export default function SubjectPassRateChart({ data }: SubjectPassRateChartProps) {
  const categories = data.map((d) => d.subject_name);
  const passRates = data.map((d) => parseFloat(String(d.pass_rate_percent || 0)));

  const backgroundColors = passRates.map((rate) =>
    rate >= 80 ? '#10b981' : rate >= 50 ? '#f59e0b' : '#ef4444'
  );

  const hoverColors = passRates.map((rate) =>
    rate >= 80 ? '#059669' : rate >= 50 ? '#d97706' : '#dc2626'
  );

  const chartData = {
    labels: categories.length > 0 ? categories : ['Chưa có dữ liệu'],
    datasets: [
      {
        label: 'Tỷ lệ đạt (%)',
        data: passRates,
        backgroundColor: backgroundColors,
        hoverBackgroundColor: hoverColors,
        borderRadius: 6,
        barPercentage: 0.65,
        categoryPercentage: 0.8,
      },
    ],
  };

  const options: any = {
    indexAxis: 'y' as const,
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false,
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
            const item = data[idx];
            const rate = context.raw;
            if (!item) return ` ${rate}%`;
            return ` Tỷ lệ đạt: ${rate}% (Đạt ${item.passed_count}/${item.total_candidates} HV)`;
          },
        },
      },
    },
    scales: {
      x: {
        min: 0,
        max: 100,
        grid: {
          color: '#f3f4f6',
        },
        ticks: {
          color: '#6b7280',
          font: { family: 'Inter, sans-serif', size: 11 },
          callback: (value: number) => `${value}%`,
        },
      },
      y: {
        grid: {
          display: false,
        },
        ticks: {
          color: '#374151',
          font: {
            family: 'Inter, sans-serif',
            size: 11,
            weight: '500',
          },
        },
      },
    },
  };

  return (
    <div className="w-full h-[300px]">
      <Bar data={chartData} options={options} />
    </div>
  );
}
