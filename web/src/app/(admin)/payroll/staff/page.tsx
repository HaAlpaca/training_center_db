'use client';

import React, { useState, useEffect } from 'react';
import { calculateStaffSalary } from '@/actions/payroll';
import { Calculator, AlertTriangle } from 'lucide-react';

export default function StaffPayrollPage() {
  const [ratePerStudent, setRatePerStudent] = useState(50000);
  const [data, setData] = useState<any[]>([]);
  const [summary, setSummary] = useState<any | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleCalculate = async () => {
    setLoading(true);
    setError(null);
    const res = await calculateStaffSalary(ratePerStudent);
    if (res.success && res.data) {
      setData(res.data);
      setSummary(res.summary);
    } else {
      setError(res.error || 'Có lỗi xảy ra khi tính lương nhân viên');
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
        <div className="inline-flex items-center gap-2 rounded-md bg-purple-50 px-2.5 py-1 text-xs font-semibold text-purple-700 dark:bg-purple-900/30 dark:text-purple-300 mb-2">
          Yêu Cầu 5 Đề Bài
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Bảng Tính Lương & Thưởng Nhân Viên
        </h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Công thức: <strong className="text-brand-500 font-mono">Lương = Lương cứng (5tr) + Lương quản lý CTĐT (theo số học viên) + Thưởng cấp dưới (5% lương cứng × số cấp dưới)</strong>
        </p>
      </div>

      {/* Control Box: Rate per student */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end">
          <div className="flex-1 max-w-md">
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Đơn Giá Quản Lý Cho Mỗi Học Viên (VND / Học viên) *
            </label>
            <input
              type="number"
              step={5000}
              value={ratePerStudent}
              onChange={(e) => setRatePerStudent(parseInt(e.target.value, 10))}
              className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
            />
            <span className="text-[11px] text-gray-400">
              Mặc định: 50,000 VND / học viên thuộc các chương trình nhân viên đang quản lý
            </span>
          </div>

          <div>
            <button
              onClick={handleCalculate}
              disabled={loading}
              className="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 py-2.5 px-6 text-sm font-semibold text-white hover:bg-brand-600 transition"
            >
              <Calculator className="h-4 w-4" />
              <span>{loading ? 'Đang tính toán...' : 'Tính Lương Nhân Sự'}</span>
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-medium text-red-700">
          <AlertTriangle className="h-4 w-4 text-red-600" />
          <span>{error}</span>
        </div>
      )}

      {/* Summary KPI Cards */}
      {summary && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div className="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
            <span className="text-xs text-gray-500 font-semibold uppercase">Tổng Số Nhân Viên</span>
            <div className="mt-1 text-2xl font-bold text-gray-900 dark:text-white">
              {summary.totalStaff} nhân sự
            </div>
          </div>
          <div className="rounded-xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
            <span className="text-xs text-gray-500 font-semibold uppercase">Lương Cứng Cơ Bản</span>
            <div className="mt-1 text-2xl font-bold text-purple-600">
              5,000,000 VND / tháng
            </div>
          </div>
          <div className="rounded-xl border border-purple-200 bg-purple-50 p-4 dark:border-purple-900/40 dark:bg-purple-900/20">
            <span className="text-xs text-purple-700 dark:text-purple-300 font-semibold uppercase">
              Tổng Quỹ Lương Chi Trả
            </span>
            <div className="mt-1 text-2xl font-black text-purple-900 dark:text-white">
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
                <th className="px-4 py-3.5">Mã NV</th>
                <th className="px-4 py-3.5">Họ và Tên Nhân Viên</th>
                <th className="px-4 py-3.5">Vị Trí Công Tác</th>
                <th className="px-4 py-3.5 text-right">Lương Cứng</th>
                <th className="px-4 py-3.5 text-center">Cấp Dưới (+5%/người)</th>
                <th className="px-4 py-3.5 text-center">Học Viên Quản Lý</th>
                <th className="px-4 py-3.5 text-right font-bold">Tổng Thu Nhập</th>
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
                    Chưa có dữ liệu nhân viên
                  </td>
                </tr>
              ) : (
                data.map((row) => {
                  const base = Number(row.base_salary || 5000000);
                  const subCount = Number(row.subordinates_count || 0);
                  const subBonus = Number(row.management_bonus || 0);
                  const stuCount = Number(row.managed_students_count || 0);
                  const progPay = Number(row.program_management_pay || 0);
                  const total = Number(row.total_income || 0);

                  return (
                    <tr key={row.staff_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5 font-bold text-xs text-gray-900 dark:text-white">
                        {row.staff_id}
                      </td>
                      <td className="px-4 py-3.5 font-semibold text-gray-900 dark:text-white">
                        {row.full_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs text-gray-500">
                        {row.staff_position}
                      </td>
                      <td className="px-4 py-3.5 text-right font-mono text-xs">
                        {base.toLocaleString('vi-VN')} đ
                      </td>
                      <td className="px-4 py-3.5 text-center text-xs">
                        <span className="font-bold text-gray-900 dark:text-white">
                          {subCount} người
                        </span>
                        {subCount > 0 && (
                          <span className="block text-[10px] text-green-600 font-medium">
                            (+{subBonus.toLocaleString('vi-VN')} đ)
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-center text-xs">
                        <span className="font-bold text-gray-900 dark:text-white">
                          {stuCount} học viên
                        </span>
                        {stuCount > 0 && (
                          <span className="block text-[10px] text-brand-600 font-medium">
                            (+{progPay.toLocaleString('vi-VN')} đ)
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-right font-black text-purple-600 dark:text-purple-400 text-sm">
                        {new Intl.NumberFormat('vi-VN', {
                          style: 'currency',
                          currency: 'VND',
                        }).format(total)}
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
