'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { getStudentTranscript, getStudents } from '@/actions/students';

function TranscriptContent() {
  const searchParams = useSearchParams();
  const initialStudentId = searchParams.get('student_id') || 'STU_001';

  const [studentId, setStudentId] = useState(initialStudentId);
  const [students, setStudents] = useState<any[]>([]);
  const [data, setData] = useState<any | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load student dropdown list
  useEffect(() => {
    getStudents().then((res) => {
      if (res.success) setStudents(res.data);
    });
  }, []);

  // Fetch transcript when studentId changes
  const fetchTranscript = async (id: string) => {
    if (!id.trim()) return;
    setLoading(true);
    setError(null);
    const res = await getStudentTranscript(id.trim());
    if (res.success) {
      setData(res);
    } else {
      setError(res.error || 'Không tìm thấy bảng điểm');
      setData(null);
    }
    setLoading(false);
  };

  useEffect(() => {
    if (initialStudentId) {
      fetchTranscript(initialStudentId);
    }
  }, [initialStudentId]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchTranscript(studentId);
  };

  return (
    <div className="space-y-6">
      {/* Title */}
      <div>
        <div className="inline-flex items-center gap-2 rounded-md bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 mb-2">
          Yêu Cầu 2 Đề Bài
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Tra Cứu Bảng Điểm & Kết Quả Học Tập
        </h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Hiển thị kết quả học tập của mỗi học viên trong các khóa đào tạo họ đã hoàn thành (gọi Function{' '}
          <code className="text-brand-500">fn_get_student_academic_transcript</code> và tính GPA)
        </p>
      </div>

      {/* Search / Select Student Box */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <form onSubmit={handleSearch} className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className="flex-1">
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Chọn hoặc nhập Mã Học Viên
            </label>
            <div className="flex gap-2">
              <select
                value={studentId}
                onChange={(e) => {
                  setStudentId(e.target.value);
                  fetchTranscript(e.target.value);
                }}
                className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
              >
                {students.map((s) => (
                  <option key={s.student_id} value={s.student_id}>
                    {s.student_id} — {s.full_name} ({s.phone_number})
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="sm:self-end">
            <button
              type="submit"
              disabled={loading}
              className="w-full sm:w-auto inline-flex items-center justify-center rounded-lg bg-brand-500 px-6 py-2.5 text-sm font-semibold text-white hover:bg-brand-600 transition"
            >
              {loading ? 'Đang tra cứu...' : '🔍 Xem Bảng Điểm'}
            </button>
          </div>
        </form>
      </div>

      {/* Error display */}
      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-medium text-red-700 dark:border-red-800/40 dark:bg-red-900/30 dark:text-red-300">
          ⚠️ {error}
        </div>
      )}

      {/* Transcript Results */}
      {data && data.student && (
        <div className="space-y-6">
          {/* Student Profile Card */}
          <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <span className="text-xs font-semibold text-brand-500 uppercase">Hồ Sơ Học Viên</span>
                <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                  {data.student.full_name}
                </h2>
                <div className="mt-1 flex flex-wrap gap-4 text-xs text-gray-500 dark:text-gray-400">
                  <span>
                    Mã HV: <strong className="text-gray-900 dark:text-white">{data.student.student_id}</strong>
                  </span>
                  <span>
                    SĐT: <strong className="text-gray-900 dark:text-white">{data.student.phone_number}</strong>
                  </span>
                  <span>
                    Email: <strong className="text-gray-900 dark:text-white">{data.student.email || '—'}</strong>
                  </span>
                </div>
              </div>
              <div>
                <span className="inline-block px-3 py-1 rounded-full text-xs font-bold bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300">
                  Trạng thái: {data.student.status}
                </span>
              </div>
            </div>

            {/* GPA per Class Summary Cards */}
            {data.classSummaries && data.classSummaries.length > 0 && (
              <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 border-t pt-4 dark:border-gray-800">
                {data.classSummaries.map((cs: any) => (
                  <div
                    key={cs.class_id}
                    className="rounded-xl border border-gray-100 bg-gray-50/70 p-3.5 dark:border-gray-800 dark:bg-gray-800/40"
                  >
                    <span className="text-xs text-gray-400 font-medium">{cs.class_name}</span>
                    <div className="mt-1 flex items-baseline justify-between">
                      <span className="text-xl font-black text-brand-600">
                        GPA: {cs.class_gpa ? cs.class_gpa : 'Chưa có'}
                      </span>
                      <span className="text-[11px] text-gray-500">
                        {cs.graded_subjects_count} môn đã có điểm
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Detailed Academic Transcript Table */}
          <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
            <div className="p-4 border-b border-gray-100 dark:border-gray-800">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">
                Chi Tiết Điểm Thi Các Môn Học & Các Lần Dự Thi
              </h3>
              <p className="text-xs text-gray-400">
                Lưu lại toàn bộ lịch sử các lần thi. Điểm trên 5.0 được tính là qua môn (ĐẠT).
              </p>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
                <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
                  <tr>
                    <th className="px-4 py-3.5">Lớp Đào Tạo</th>
                    <th className="px-4 py-3.5">Mã Môn</th>
                    <th className="px-4 py-3.5">Tên Môn Học</th>
                    <th className="px-4 py-3.5 text-center">Lần Thi</th>
                    <th className="px-4 py-3.5 text-center">Điểm Số (Hệ 10)</th>
                    <th className="px-4 py-3.5 text-center">Ngày Thi</th>
                    <th className="px-4 py-3.5 text-center">Đánh Giá Kết Quả</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {data.transcript.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-gray-400">
                        Học viên chưa có bản ghi điểm thi nào trong CSDL
                      </td>
                    </tr>
                  ) : (
                    data.transcript.map((row: any, idx: number) => {
                      const score = row.score !== null ? parseFloat(row.score) : null;
                      const isPassed = score !== null && score > 5.0;
                      const isFailed = score !== null && score <= 5.0;

                      return (
                        <tr key={idx} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                          <td className="px-4 py-3.5 font-medium text-gray-900 dark:text-white text-xs">
                            {row.class_name}
                          </td>
                          <td className="px-4 py-3.5 text-xs font-mono">{row.subject_id}</td>
                          <td className="px-4 py-3.5 font-semibold text-gray-900 dark:text-white">
                            {row.subject_name}
                          </td>
                          <td className="px-4 py-3.5 text-center text-xs font-bold">
                            {row.attempt_number ? `Lần ${row.attempt_number}` : '—'}
                          </td>
                          <td className="px-4 py-3.5 text-center">
                            {score !== null ? (
                              <span
                                className={`text-base font-bold ${
                                  isPassed ? 'text-green-600' : 'text-red-500'
                                }`}
                              >
                                {score.toFixed(1)}
                              </span>
                            ) : (
                              <span className="text-gray-400 text-xs italic">Chưa dự thi</span>
                            )}
                          </td>
                          <td className="px-4 py-3.5 text-center text-xs text-gray-500">
                            {row.exam_date
                              ? new Date(row.exam_date).toLocaleDateString('vi-VN')
                              : '—'}
                          </td>
                          <td className="px-4 py-3.5 text-center">
                            {score === null ? (
                              <span className="inline-block px-2.5 py-0.5 rounded text-xs font-semibold bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300">
                                CHƯA DỰ THI
                              </span>
                            ) : isPassed ? (
                              <span className="inline-block px-2.5 py-0.5 rounded text-xs font-bold bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300">
                                ✅ ĐẠT (PASSED)
                              </span>
                            ) : (
                              <span className="inline-block px-2.5 py-0.5 rounded text-xs font-bold bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300">
                                ❌ CHƯA ĐẠT (FAILED)
                              </span>
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
      )}
    </div>
  );
}

export default function TranscriptsPage() {
  return (
    <Suspense fallback={<div className="p-8 text-center text-gray-400">Đang tải bảng điểm...</div>}>
      <TranscriptContent />
    </Suspense>
  );
}
