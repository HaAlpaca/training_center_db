'use client';

import React, { useState, useEffect } from 'react';
import { getClasses } from '@/actions/classes';
import { getIncompleteStudentsByClass } from '@/actions/academic';
import { RefreshCw, CheckCircle2 } from 'lucide-react';

export default function IncompleteStudentsPage() {
  const [classes, setClasses] = useState<any[]>([]);
  const [selectedClassId, setSelectedClassId] = useState('PRG_DATA_FALL_2026');
  const [incompleteList, setIncompleteList] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  // Load classes dropdown
  useEffect(() => {
    getClasses().then((res) => {
      if (res.success) {
        setClasses(res.data);
        if (res.data.length > 0 && !selectedClassId) {
          setSelectedClassId(res.data[0].class_id);
        }
      }
    });
  }, []);

  // Fetch incomplete students when class changes
  const fetchIncomplete = async (classId: string) => {
    if (!classId) return;
    setLoading(true);
    const res = await getIncompleteStudentsByClass(classId);
    if (res.success) {
      setIncompleteList(res.data);
    } else {
      setIncompleteList([]);
    }
    setLoading(false);
  };

  useEffect(() => {
    if (selectedClassId) {
      fetchIncomplete(selectedClassId);
    }
  }, [selectedClassId]);

  return (
    <div className="space-y-6">
      {/* Title */}
      <div>
        <div className="inline-flex items-center gap-2 rounded-md bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700 dark:bg-red-900/30 dark:text-red-300 mb-2">
          Yêu Cầu 3 Đề Bài
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Học Viên Chưa Hoàn Thành Môn Học & Điểm Rớt
        </h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Liệt kê toàn bộ các học viên chưa hoàn thành xong các môn học của khóa đào tạo kèm điểm thi của các môn học chưa đạt yêu cầu qua các lần dự thi (sử dụng hàm{' '}
          <code className="text-brand-500">STRING_AGG</code> tổng hợp lịch sử)
        </p>
      </div>

      {/* Class Selector Filter */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className="flex-1">
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Chọn Khóa Đào Tạo Cần Kiểm Tra Nợ Môn
            </label>
            <select
              value={selectedClassId}
              onChange={(e) => setSelectedClassId(e.target.value)}
              className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white font-medium"
            >
              {classes.map((c) => (
                <option key={c.class_id} value={c.class_id}>
                  {c.class_name} ({c.class_id}) — {c.program_name}
                </option>
              ))}
            </select>
          </div>
          <div className="sm:self-end">
            <button
              onClick={() => fetchIncomplete(selectedClassId)}
              disabled={loading}
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-6 py-2.5 text-sm font-semibold text-white hover:bg-brand-600 transition"
            >
              <RefreshCw className="h-4 w-4" />
              <span>{loading ? 'Đang lọc...' : 'Làm Mới Dữ Liệu'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Summary Stat Banner */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-900/40 dark:bg-amber-900/20">
          <span className="text-xs text-amber-700 dark:text-amber-300 font-semibold uppercase">
            Tổng Lượt Chưa Đạt / Nợ Môn
          </span>
          <div className="mt-1 text-2xl font-bold text-amber-900 dark:text-white">
            {incompleteList.length} lượt
          </div>
        </div>
        <div className="rounded-xl border border-red-200 bg-red-50 p-4 dark:border-red-900/40 dark:bg-red-900/20">
          <span className="text-xs text-red-700 dark:text-red-300 font-semibold uppercase">
            Đã Dự Thi Nhưng Bị Rớt (&le; 5.0)
          </span>
          <div className="mt-1 text-2xl font-bold text-red-900 dark:text-white">
            {incompleteList.filter((i) => i.failed_attempts_count > 0).length} lượt
          </div>
        </div>
        <div className="rounded-xl border border-gray-200 bg-gray-50 p-4 dark:border-gray-800 dark:bg-gray-800">
          <span className="text-xs text-gray-500 dark:text-gray-400 font-semibold uppercase">
            Chưa Tham Gia Dự Thi
          </span>
          <div className="mt-1 text-2xl font-bold text-gray-900 dark:text-white">
            {incompleteList.filter((i) => i.failed_attempts_count === 0).length} lượt
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
              <tr>
                <th className="px-4 py-3.5">Học Viên</th>
                <th className="px-4 py-3.5">Môn Học Nợ</th>
                <th className="px-4 py-3.5 text-center">Tình Trạng</th>
                <th className="px-4 py-3.5 text-center">Số Lần Thi Rớt</th>
                <th className="px-4 py-3.5">Chi Tiết Lịch Sử Các Lần Thi Chưa Đạt (STRING_AGG)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-gray-400">
                    Đang tính toán danh sách học viên nợ môn...
                  </td>
                </tr>
              ) : incompleteList.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-green-600 font-semibold">
                    <div className="inline-flex items-center gap-2">
                      <CheckCircle2 className="h-5 w-5 text-green-600" />
                      <span>Tuyệt vời! Khóa học này không có học viên nào nợ môn (100% hoàn thành môn học).</span>
                    </div>
                  </td>
                </tr>
              ) : (
                incompleteList.map((item, idx) => {
                  const isFailed = Number(item.failed_attempts_count) > 0;
                  return (
                    <tr key={idx} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5">
                        <span className="font-bold text-gray-900 dark:text-white block">
                          {item.student_name}
                        </span>
                        <span className="text-xs text-gray-400 font-mono">{item.student_id}</span>
                      </td>
                      <td className="px-4 py-3.5">
                        <span className="font-semibold text-gray-900 dark:text-white block">
                          {item.subject_name}
                        </span>
                        <span className="text-xs text-gray-400 font-mono">{item.subject_id}</span>
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span
                          className={`inline-block px-2.5 py-0.5 rounded text-xs font-bold ${
                            isFailed
                              ? 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300'
                              : 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300'
                          }`}
                        >
                          {item.completion_status}
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        {isFailed ? (
                          <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white">
                            {item.failed_attempts_count}
                          </span>
                        ) : (
                          <span className="text-gray-400 text-xs">—</span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-xs">
                        {isFailed ? (
                          <div className="font-medium text-red-600 dark:text-red-400 bg-red-50/70 dark:bg-red-900/20 p-2 rounded-lg border border-red-100 dark:border-red-900/30">
                            {item.failed_exam_details}
                          </div>
                        ) : (
                          <span className="text-gray-400 italic">Chưa có lượt thi nào</span>
                        )}
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
