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

interface CourseRevenueChartProps {
  data: Array<{
    class_id: string;
    class_name: string;
    program_name: string;
    current_students: number;
    total_tuition_collected: number;
  }>;
}

export default function CourseRevenueChart({ data }: CourseRevenueChartProps) {
  const categories = data.map((d) => {
    const parts = d.class_name.split(' - ');
    return parts[0] || d.class_id;
  });

  const revenueData = data.map((d) =>
    Math.round(Number(d.total_tuition_collected || 0) / 1000000)
  );
  const studentsData = data.map((d) => Number(d.current_students || 0));

  const chartData = {
    labels: categories.length > 0 ? categories : ['Chưa có dữ liệu'],
    datasets: [
      {
        label: 'Doanh Thu (Triệu VNĐ)',
        data: revenueData,
        backgroundColor: '#465fff',
        hoverBackgroundColor: '#3641f5',
        borderRadius: 6,
        yAxisID: 'y',
        barPercentage: 0.6,
        categoryPercentage: 0.7,
      },
      {
        label: 'Sĩ Số (Học Viên)',
        data: studentsData,
        backgroundColor: '#10b981',
        hoverBackgroundColor: '#059669',
        borderRadius: 6,
        yAxisID: 'y1',
        barPercentage: 0.6,
        categoryPercentage: 0.7,
      },
    ],
  };

  const options: any = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
        align: 'end' as const,
        labels: {
          usePointStyle: true,
          pointStyle: 'circle',
          boxWidth: 8,
          boxHeight: 8,
          padding: 16,
          font: {
            family: 'Inter, sans-serif',
            size: 12,
            weight: '500',
          },
          color: '#6b7280',
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
            const val = context.raw;
            if (context.datasetIndex === 0) {
              return ` Doanh Thu: ${Number(val).toLocaleString('vi-VN')} Triệu VNĐ`;
            }
            return ` Sĩ Số: ${val} Học viên`;
          },
        },
      },
    },
    scales: {
      x: {
        grid: {
          display: false,
        },
        ticks: {
          font: {
            family: 'Inter, sans-serif',
            size: 11,
            weight: '500',
          },
          color: '#6b7280',
        },
      },
      y: {
        type: 'linear' as const,
        display: true,
        position: 'left' as const,
        title: {
          display: true,
          text: 'Doanh Thu (Triệu VNĐ)',
          color: '#465fff',
          font: { family: 'Inter, sans-serif', size: 11, weight: '600' },
        },
        grid: {
          color: '#f3f4f6',
        },
        ticks: {
          color: '#6b7280',
          font: { family: 'Inter, sans-serif', size: 11 },
          callback: (value: number) => `${value}M`,
        },
      },
      y1: {
        type: 'linear' as const,
        display: true,
        position: 'right' as const,
        title: {
          display: true,
          text: 'Sĩ Số (HV)',
          color: '#10b981',
          font: { family: 'Inter, sans-serif', size: 11, weight: '600' },
        },
        grid: {
          drawOnChartArea: false,
        },
        ticks: {
          color: '#6b7280',
          font: { family: 'Inter, sans-serif', size: 11 },
          callback: (value: number) => `${value} HV`,
        },
      },
    },
  };

  return (
    <div className="w-full h-[320px]">
      <Bar data={chartData} options={options} />
    </div>
  );
}
