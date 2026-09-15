'use client';

import React, { useState, useEffect } from 'react';
import {
  getClasses,
  createClass,
  enrollStudent,
  getClassEnrollments,
  getSemestersDropdown,
} from '@/actions/classes';
import { getPrograms } from '@/actions/programs';
import { getStudents } from '@/actions/students';
import { Plus, Users, X, CheckCircle2, AlertCircle } from 'lucide-react';

export default function ClassesPage() {
  const [classes, setClasses] = useState<any[]>([]);
  const [programs, setPrograms] = useState<any[]>([]);
  const [semesters, setSemesters] = useState<any[]>([]);
  const [students, setStudents] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  // Modal Create Class
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [classForm, setClassForm] = useState({
    class_id: '',
    class_name: '',
    program_id: '',
    semester_id: '',
    max_capacity: 25,
    status: 'OPEN',
  });

  // Modal Enroll
  const [selectedClass, setSelectedClass] = useState<any | null>(null);
  const [enrollStudentId, setEnrollStudentId] = useState('');
  const [tuitionPaid, setTuitionPaid] = useState(15000000);

  // Modal View Students in Class
  const [viewingClass, setViewingClass] = useState<any | null>(null);
  const [enrollments, setEnrollments] = useState<any[]>([]);
  const [loadingEnrollments, setLoadingEnrollments] = useState(false);

  const [alertMsg, setAlertMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadData = async () => {
    setLoading(true);
    const [cRes, pRes, semRes, stuRes] = await Promise.all([
      getClasses(search),
      getPrograms(),
      getSemestersDropdown(),
      getStudents(),
    ]);
    if (cRes.success) setClasses(cRes.data);
    if (pRes.success) {
      setPrograms(pRes.data);
      if (pRes.data.length > 0 && !classForm.program_id) {
        setClassForm((prev) => ({ ...prev, program_id: pRes.data[0].program_id }));
      }
    }
    if (semRes.success) {
      setSemesters(semRes.data);
      if (semRes.data.length > 0 && !classForm.semester_id) {
        setClassForm((prev) => ({ ...prev, semester_id: semRes.data[0].semester_id }));
      }
    }
    if (stuRes.success) {
      setStudents(stuRes.data);
      if (stuRes.data.length > 0 && !enrollStudentId) {
        setEnrollStudentId(stuRes.data[0].student_id);
      }
    }
    setLoading(false);
  };

  useEffect(() => {
    loadData();
  }, [search]);

  // Handle Create Class
  const handleCreateClass = async (e: React.FormEvent) => {
    e.preventDefault();
    setAlertMsg(null);
    const res = await createClass(classForm);
    if (res.success) {
      setAlertMsg({ text: res.message || 'Tạo lớp thành công!', type: 'success' });
      setIsCreateOpen(false);
      setClassForm({
        class_id: '',
        class_name: '',
        program_id: programs[0]?.program_id || '',
        semester_id: semesters[0]?.semester_id || '',
        max_capacity: 25,
        status: 'OPEN',
      });
      loadData();
    } else {
      setAlertMsg({ text: res.error, type: 'error' });
    }
  };

  // Handle Enroll Student (Validation 6.2)
  const handleEnroll = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedClass) return;

    if (Number(selectedClass.current_enrolled) >= Number(selectedClass.max_capacity)) {
      alert('Lớp học đã đầy (FULL). Ràng buộc số lượng không cho phép đăng ký thêm!');
      return;
    }

    const res = await enrollStudent({
      class_id: selectedClass.class_id,
      student_id: enrollStudentId,
      tuition_paid: tuitionPaid,
    });

    if (res.success) {
      alert(res.message);
      setSelectedClass(null);
      loadData();
    } else {
      alert(res.error);
    }
  };

  // View Class Students
  const handleViewStudents = async (c: any) => {
    setViewingClass(c);
    setLoadingEnrollments(true);
    const res = await getClassEnrollments(c.class_id);
    if (res.success) setEnrollments(res.data);
    setLoadingEnrollments(false);
  };

  return (
    <div className="space-y-6">
      {/* Title */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Khóa Đào Tạo & Quản Lý Sĩ Số
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Quản lý các khóa học, kiểm soát sĩ số tối đa (Max capacity) và ghi danh học viên
          </p>
        </div>
        <button
          onClick={() => setIsCreateOpen(true)}
          className="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 transition"
        >
          <Plus className="h-4 w-4" />
          <span>Mở Lớp Học Mới</span>
        </button>
      </div>

      {alertMsg && (
        <div
          className={`p-4 rounded-lg text-sm font-medium ${
            alertMsg.type === 'success'
              ? 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300'
              : 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-300'
          }`}
        >
          {alertMsg.text}
        </div>
      )}

      {/* Search Input */}
      <div className="relative max-w-md">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Tìm kiếm theo mã lớp hoặc chương trình..."
          className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-brand-500 focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
        />
      </div>

      {/* Classes Table */}
      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
              <tr>
                <th className="px-4 py-3.5">Mã Lớp</th>
                <th className="px-4 py-3.5">Tên Khóa Học</th>
                <th className="px-4 py-3.5">Chương Trình</th>
                <th className="px-4 py-3.5">Kỳ Học</th>
                <th className="px-4 py-3.5 text-center">Sĩ Số Thực Tế</th>
                <th className="px-4 py-3.5 text-center">Trạng Thái Sĩ Số</th>
                <th className="px-4 py-3.5 text-center">Trạng Thái Lớp</th>
                <th className="px-4 py-3.5 text-right">Thao Tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-gray-400">
                    Đang tải dữ liệu lớp học...
                  </td>
                </tr>
              ) : classes.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-gray-400">
                    Không tìm thấy lớp học nào
                  </td>
                </tr>
              ) : (
                classes.map((c) => {
                  const enrolled = Number(c.current_enrolled || 0);
                  const maxCap = Number(c.max_capacity || 0);
                  const isFull = enrolled >= maxCap;
                  const remaining = Math.max(0, maxCap - enrolled);

                  return (
                    <tr key={c.class_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5 font-bold text-gray-900 dark:text-white">
                        {c.class_id}
                      </td>
                      <td className="px-4 py-3.5 font-medium text-gray-900 dark:text-white">
                        {c.class_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs text-gray-500 dark:text-gray-400">
                        {c.program_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs">{c.semester_name}</td>
                      <td className="px-4 py-3.5 text-center">
                        <span className="font-bold text-gray-900 dark:text-white">
                          {enrolled}
                        </span>{' '}
                        / <span className="text-gray-400">{maxCap}</span>
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        {isFull ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded text-xs font-bold bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300">
                            <AlertCircle className="h-3.5 w-3.5 text-red-600 dark:text-red-400" />
                            <span>ĐÃ ĐẦY (FULL)</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded text-xs font-semibold bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300">
                            <CheckCircle2 className="h-3.5 w-3.5 text-green-600 dark:text-green-400" />
                            <span>Còn {remaining} chỗ</span>
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span className="inline-block px-2 py-0.5 rounded text-[11px] font-medium bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300">
                          {c.status}
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleViewStudents(c)}
                            className="inline-flex items-center gap-1 rounded-md border border-brand-200 bg-brand-50/50 px-2.5 py-1 text-xs font-semibold text-brand-600 shadow-sm transition hover:bg-brand-100 dark:border-brand-800/40 dark:bg-brand-950/30 dark:text-brand-400 dark:hover:bg-brand-900/40"
                          >
                            <Users className="h-3 w-3" />
                            <span>HV ({enrolled})</span>
                          </button>
                          <button
                            disabled={isFull}
                            onClick={() => setSelectedClass(c)}
                            className={`inline-flex items-center gap-1 rounded-md px-2.5 py-1 text-xs font-semibold shadow-sm transition ${
                              isFull
                                ? 'bg-gray-100 text-gray-400 cursor-not-allowed border border-gray-200 dark:bg-gray-800 dark:border-gray-700'
                                : 'bg-brand-600 text-white hover:bg-brand-700 cursor-pointer'
                            }`}
                          >
                            <Plus className="h-3 w-3" />
                            <span>Ghi danh</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Mở Lớp Mới */}
      {isCreateOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
              Mở Khóa Đào Tạo / Lớp Học Mới
            </h2>
            <form onSubmit={handleCreateClass} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Mã Lớp (Thể hiện CTĐT & Kỳ học, vd: PRG_DATA_FALL_2026) *
                </label>
                <input
                  type="text"
                  required
                  placeholder="PRG_..._KỲ_NĂM"
                  value={classForm.class_id}
                  onChange={(e) => setClassForm({ ...classForm, class_id: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Tên Khóa / Lớp Học *
                </label>
                <input
                  type="text"
                  required
                  placeholder="vd: Data Analytics Fall 2026"
                  value={classForm.class_name}
                  onChange={(e) => setClassForm({ ...classForm, class_name: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Chương Trình Đào Tạo *
                  </label>
                  <select
                    value={classForm.program_id}
                    onChange={(e) => setClassForm({ ...classForm, program_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    {programs.map((p) => (
                      <option key={p.program_id} value={p.program_id}>
                        {p.program_name} ({p.program_id})
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Học Kỳ *
                  </label>
                  <select
                    value={classForm.semester_id}
                    onChange={(e) => setClassForm({ ...classForm, semester_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    {semesters.map((s) => (
                      <option key={s.semester_id} value={s.semester_id}>
                        {s.semester_name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Sĩ Số Tối Đa (Max Capacity) *
                </label>
                <input
                  type="number"
                  min={1}
                  max={100}
                  required
                  value={classForm.max_capacity}
                  onChange={(e) =>
                    setClassForm({ ...classForm, max_capacity: parseInt(e.target.value, 10) })
                  }
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>

              <div className="mt-6 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  className="rounded-lg px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-brand-500 px-5 py-2 text-sm font-medium text-white hover:bg-brand-600"
                >
                  Tạo Lớp
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Ghi Danh Học Viên (Validation Sĩ Số) */}
      {selectedClass && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
              Ghi Danh Học Viên Vào Lớp
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
              Lớp: <span className="font-semibold text-brand-500">{selectedClass.class_name}</span>{' '}
              ({selectedClass.current_enrolled}/{selectedClass.max_capacity} học viên)
            </p>

            <form onSubmit={handleEnroll} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Chọn Học Viên *
                </label>
                <select
                  value={enrollStudentId}
                  onChange={(e) => setEnrollStudentId(e.target.value)}
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                >
                  {students.map((s) => (
                    <option key={s.student_id} value={s.student_id}>
                      {s.full_name} ({s.student_id} - SĐT: {s.phone_number})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Học Phí Đã Thu (VND)
                </label>
                <input
                  type="number"
                  step={100000}
                  value={tuitionPaid}
                  onChange={(e) => setTuitionPaid(parseInt(e.target.value, 10))}
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>

              <div className="mt-6 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setSelectedClass(null)}
                  className="rounded-lg px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-brand-500 px-5 py-2 text-sm font-medium text-white hover:bg-brand-600"
                >
                  Xác Nhận Ghi Danh
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Xem Danh Sách Học Viên Trong Lớp */}
      {viewingClass && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-2xl max-h-[85vh] overflow-y-auto rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <div className="flex items-center justify-between border-b pb-3 dark:border-gray-800 mb-4">
              <div>
                <h2 className="text-lg font-bold text-gray-900 dark:text-white">
                  Danh Sách Học Viên Lớp: {viewingClass.class_name}
                </h2>
                <p className="text-xs text-gray-400">
                  Sĩ số: {viewingClass.current_enrolled} / {viewingClass.max_capacity} học viên
                </p>
              </div>
              <button
                onClick={() => setViewingClass(null)}
                className="text-gray-400 hover:text-gray-600 dark:hover:text-white p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
                <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
                  <tr>
                    <th className="px-3 py-2.5">Mã SV</th>
                    <th className="px-3 py-2.5">Họ Tên</th>
                    <th className="px-3 py-2.5">SĐT</th>
                    <th className="px-3 py-2.5 text-right">Học Phí</th>
                    <th className="px-3 py-2.5 text-center">Trạng Thái</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {loadingEnrollments ? (
                    <tr>
                      <td colSpan={5} className="py-6 text-center text-gray-400">
                        Đang tải...
                      </td>
                    </tr>
                  ) : enrollments.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="py-6 text-center text-gray-400">
                        Chưa có học viên nào ghi danh vào lớp này
                      </td>
                    </tr>
                  ) : (
                    enrollments.map((e) => (
                      <tr key={e.enrollment_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                        <td className="px-3 py-2.5 font-bold text-xs text-gray-900 dark:text-white">
                          {e.student_id}
                        </td>
                        <td className="px-3 py-2.5 font-medium text-xs text-gray-900 dark:text-white">
                          {e.student_name}
                        </td>
                        <td className="px-3 py-2.5 text-xs">{e.phone_number}</td>
                        <td className="px-3 py-2.5 text-right text-xs font-semibold text-emerald-600">
                          {new Intl.NumberFormat('vi-VN', {
                            style: 'currency',
                            currency: 'VND',
                          }).format(Number(e.tuition_paid || 0))}
                        </td>
                        <td className="px-3 py-2.5 text-center">
                          <span className="inline-block px-2 py-0.5 rounded text-[10px] font-semibold bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300">
                            {e.status}
                          </span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            <div className="mt-5 flex justify-end">
              <button
                onClick={() => setViewingClass(null)}
                className="rounded-lg bg-gray-100 dark:bg-gray-800 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-200"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
