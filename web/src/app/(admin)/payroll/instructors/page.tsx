'use client';

import React, { useState, useEffect } from 'react';
import { calculateInstructorSalary } from '@/actions/payroll';

export default function InstructorPayrollPage() {
  const [month, setMonth] = useState(9);
  const [year, setYear] = useState(2026);
  const [rate, setRate] = useState(200000);
  const [data, setData] = useState<any[]>([]);
  const [summary, setSummary] = useState<any | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleCalculate = async () => {
    setLoading(true);
    setError(null);
    const res = await calculateInstructorSalary(month, year, rate);
    if (res.success && res.data) {
      setData(res.data);
      setSummary(res.summary);
    } else {
      setError(res.error || 'Có lỗi xảy ra khi tính lương');
      setData([]);
    }
    setLoading(false);
  };

  useEffect(() => {
    handleCalculate();
  }, []);

  return (
    <div className="space-y-6">
      {/* Title */}
      <div>
        <div className="inline-flex items-center gap-2 rounded-md bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300 mb-2">
          Yêu Cầu 4 Đề Bài
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Bảng Tính Thù Lao Giảng Viên Trong Tháng
        </h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Lương giảng viên được tính dựa trên số giờ dạy thực tế trên lớp trong tháng. Lương dạy chính gấp đôi trợ giảng:{' '}
          <strong className="text-brand-500 font-mono">
            Lương = (Giờ dạy chính × Đơn giá) + (Giờ trợ giảng × Đơn giá / 2)
          </strong>
        </p>
      </div>

      {/* Control Box: Month, Year, Rate */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Tháng Giảng Dạy *
            </label>
            <select
              value={month}
              onChange={(e) => setMonth(parseInt(e.target.value, 10))}
              className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            >
              {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
                <option key={m} value={m}>
                  Tháng {m}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Năm *
            </label>
            <input
              type="number"
              value={year}
              onChange={(e) => setYear(parseInt(e.target.value, 10))}
              className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Đơn Giá Dạy Chính (VND/giờ) *
            </label>
            <input
              type="number"
              step={10000}
              value={rate}
              onChange={(e) => setRate(parseInt(e.target.value, 10))}
              className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            />
            <span className="text-[11px] text-gray-400">
              Trợ giảng: {(rate / 2).toLocaleString('vi-VN')} VND/giờ
            </span>
          </div>

          <div className="flex items-end">
            <button
              onClick={handleCalculate}
              disabled={loading}
              className="w-full rounded-lg bg-brand-500 py-2.5 px-4 text-sm font-semibold text-white hover:bg-brand-600 transition"
            >
              {loading ? 'Đang tính toán...' : '💰 Tính Lương Tháng'}
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-medium text-red-700">
          ⚠️ {error}
        </div>
      )}

      {/* Summary KPI Cards */}
      {summary && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div className="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
            <span className="text-xs text-gray-500 font-semibold uppercase">Giảng Viên Có Tiết Dạy</span>
            <div className="mt-1 text-2xl font-bold text-gray-900 dark:text-white">
              {summary.totalInstructors} người
            </div>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
            <span className="text-xs text-gray-500 font-semibold uppercase">Đơn Giá Áp Dụng</span>
            <div className="mt-1 text-2xl font-bold text-brand-600">
              {Number(summary.baseHourlyRate).toLocaleString('vi-VN')} VND / h
            </div>
          </div>
          <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4 dark:border-emerald-900/40 dark:bg-emerald-900/20">
            <span className="text-xs text-emerald-700 dark:text-emerald-300 font-semibold uppercase">
              Tổng Quỹ Lương Giảng Viên
            </span>
            <div className="mt-1 text-2xl font-black text-emerald-900 dark:text-white">
              {new Intl.NumberFormat('vi-VN', {
                style: 'currency',
                currency: 'VND',
              }).format(summary.totalPayroll)}
            </div>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
              <tr>
                <th className="px-4 py-3.5">Mã GV</th>
                <th className="px-4 py-3.5">Họ và Tên Giảng Viên</th>
                <th className="px-4 py-3.5">Loại Hợp Đồng</th>
                <th className="px-4 py-3.5 text-center">Giờ Dạy Chính (100%)</th>
                <th className="px-4 py-3.5 text-center">Giờ Trợ Giảng (50%)</th>
                <th className="px-4 py-3.5 text-right">Tổng Giờ Giảng</th>
                <th className="px-4 py-3.5 text-right font-bold">Tổng Thù Lao Thực Nhận</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    Đang tính toán lương...
                  </td>
                </tr>
              ) : data.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    Không có buổi dạy nào hoàn thành trong Tháng {month}/{year}
                  </td>
                </tr>
              ) : (
                data.map((row) => {
                  const teachHrs = Number(row.teaching_hours || 0);
                  const taHrs = Number(row.ta_hours || 0);
                  const totalHrs = teachHrs + taHrs;
                  const totalSalary = Number(row.total_salary || 0);

                  return (
                    <tr key={row.instructor_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5 font-bold text-xs text-gray-900 dark:text-white">
                        {row.instructor_id}
                      </td>
                      <td className="px-4 py-3.5 font-semibold text-gray-900 dark:text-white">
                        {row.full_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs">
                        <span
                          className={`inline-block px-2.5 py-0.5 rounded text-[11px] font-semibold ${
                            row.contract_type === 'FULLTIME'
                              ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
                              : 'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300'
                          }`}
                        >
                          {row.contract_type}
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-center font-bold text-emerald-600 text-xs">
                        {teachHrs} giờ
                      </td>
                      <td className="px-4 py-3.5 text-center font-medium text-amber-600 text-xs">
                        {taHrs} giờ
                      </td>
                      <td className="px-4 py-3.5 text-right font-mono text-xs">
                        {totalHrs} giờ
                      </td>
                      <td className="px-4 py-3.5 text-right font-black text-emerald-600 text-sm">
                        {new Intl.NumberFormat('vi-VN', {
                          style: 'currency',
                          currency: 'VND',
                        }).format(totalSalary)}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
