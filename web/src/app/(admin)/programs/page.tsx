'use client';

import React, { useState, useEffect } from 'react';
import {
  getPrograms,
  createProgram,
  deleteProgram,
  getSubjectsByProgram,
  createSubject,
  deleteSubject,
  getStaffDropdown,
} from '@/actions/programs';
import { Plus, BookOpen, AlertTriangle, X, Trash2, List } from 'lucide-react';

export default function ProgramsPage() {
  const [programs, setPrograms] = useState<any[]>([]);
  const [staffList, setStaffList] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  // Modal Program
  const [isProgramModalOpen, setIsProgramModalOpen] = useState(false);
  const [progForm, setProgForm] = useState({
    program_id: '',
    program_name: '',
    description: '',
    version: '1.0',
    manager_id: '',
  });

  // Modal Subjects
  const [selectedProgram, setSelectedProgram] = useState<any | null>(null);
  const [subjects, setSubjects] = useState<any[]>([]);
  const [loadingSubjects, setLoadingSubjects] = useState(false);
  const [subForm, setSubForm] = useState({
    subject_id: '',
    subject_name: '',
    total_hours: 30,
    subject_type: 'CORE' as 'CORE' | 'ELECTIVE',
  });

  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Load programs & staff
  const loadData = async () => {
    setLoading(true);
    const [progRes, staffRes] = await Promise.all([getPrograms(search), getStaffDropdown()]);
    if (progRes.success) setPrograms(progRes.data);
    if (staffRes.success) {
      setStaffList(staffRes.data);
      if (staffRes.data.length > 0 && !progForm.manager_id) {
        setProgForm((prev) => ({ ...prev, manager_id: staffRes.data[0].staff_id }));
      }
    }
    setLoading(false);
  };

  useEffect(() => {
    loadData();
  }, [search]);

  // Load subjects of selected program
  const openSubjectModal = async (prog: any) => {
    setSelectedProgram(prog);
    setLoadingSubjects(true);
    // Auto prefix subject_id with program_id
    setSubForm({
      subject_id: `${prog.program_id}_`,
      subject_name: '',
      total_hours: 30,
      subject_type: 'CORE',
    });
    const res = await getSubjectsByProgram(prog.program_id);
    if (res.success) setSubjects(res.data);
    setLoadingSubjects(false);
  };

  // Submit Program
  const handleCreateProgram = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(null);
    const res = await createProgram(progForm);
    if (res.success) {
      setMessage({ text: res.message || 'Tạo CTĐT thành công!', type: 'success' });
      setIsProgramModalOpen(false);
      setProgForm({
        program_id: '',
        program_name: '',
        description: '',
        version: '1.0',
        manager_id: staffList[0]?.staff_id || '',
      });
      loadData();
    } else {
      setMessage({ text: res.error, type: 'error' });
    }
  };

  // Delete Program
  const handleDeleteProgram = async (id: string) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa chương trình ${id}?`)) return;
    const res = await deleteProgram(id);
    if (res.success) {
      loadData();
    } else {
      alert(res.error);
    }
  };

  // Submit Subject (Validation tối đa 10 môn)
  const handleCreateSubject = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProgram) return;

    if (subjects.length >= 10) {
      alert('Ràng buộc nghiệp vụ: Một chương trình đào tạo chỉ được phép có tối đa 10 môn học!');
      return;
    }

    const res = await createSubject({
      ...subForm,
      program_id: selectedProgram.program_id,
    });

    if (res.success) {
      const refreshed = await getSubjectsByProgram(selectedProgram.program_id);
      if (refreshed.success) setSubjects(refreshed.data);
      setSubForm({
        subject_id: `${selectedProgram.program_id}_`,
        subject_name: '',
        total_hours: 30,
        subject_type: 'CORE',
      });
      loadData(); // Cập nhật lại số lượng đếm môn
    } else {
      alert(res.error);
    }
  };

  // Delete Subject
  const handleDeleteSubject = async (subId: string) => {
    if (!confirm(`Xóa môn học ${subId}?`)) return;
    const res = await deleteSubject(subId);
    if (res.success && selectedProgram) {
      const refreshed = await getSubjectsByProgram(selectedProgram.program_id);
      if (refreshed.success) setSubjects(refreshed.data);
      loadData();
    } else {
      alert(res.error);
    }
  };

  return (
    <div className="space-y-6">
      {/* Title & Actions */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Chương Trình Đào Tạo & Môn Học
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Quản lý danh mục CTĐT, ràng buộc tối đa 10 môn/CTĐT, phân công nhân sự quản lý
          </p>
        </div>
        <button
          onClick={() => setIsProgramModalOpen(true)}
          className="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 transition"
        >
          <Plus className="h-4 w-4" />
          <span>Thêm Chương Trình Mới</span>
        </button>
      </div>

      {/* Message alert */}
      {message && (
        <div
          className={`p-4 rounded-lg text-sm font-medium ${
            message.type === 'success'
              ? 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300'
              : 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-300'
          }`}
        >
          {message.text}
        </div>
      )}

      {/* Search Input */}
      <div className="relative max-w-md">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Tìm kiếm theo mã hoặc tên chương trình..."
          className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-brand-500 focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
        />
      </div>

      {/* Programs Table */}
      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
              <tr>
                <th className="px-4 py-3.5">Mã CTĐT</th>
                <th className="px-4 py-3.5">Tên Chương Trình</th>
                <th className="px-4 py-3.5">Phiên Bản</th>
                <th className="px-4 py-3.5">Quản Lý Phụ Trách</th>
                <th className="px-4 py-3.5 text-center">Số Môn Học (Tối đa 10)</th>
                <th className="px-4 py-3.5 text-center">Trạng Thái</th>
                <th className="px-4 py-3.5 text-right">Thao Tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    Đang tải dữ liệu...
                  </td>
                </tr>
              ) : programs.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    Không tìm thấy chương trình đào tạo nào
                  </td>
                </tr>
              ) : (
                programs.map((p) => {
                  const subjectCount = Number(p.subject_count || 0);
                  const isMaxed = subjectCount >= 10;
                  return (
                    <tr key={p.program_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5 font-bold text-gray-900 dark:text-white">
                        {p.program_id}
                      </td>
                      <td className="px-4 py-3.5">
                        <span className="font-semibold text-gray-900 dark:text-white block">
                          {p.program_name}
                        </span>
                        <span className="text-xs text-gray-400 truncate max-w-sm block">
                          {p.description}
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-xs">{p.version}</td>
                      <td className="px-4 py-3.5">
                        <span className="block font-medium text-gray-900 dark:text-white text-xs">
                          {p.manager_name}
                        </span>
                        <span className="text-[11px] text-gray-400">{p.manager_email}</span>
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <button
                          onClick={() => openSubjectModal(p)}
                          className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold cursor-pointer transition ${
                            isMaxed
                              ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                              : 'bg-brand-50 text-brand-700 hover:bg-brand-100 dark:bg-brand-900/30 dark:text-brand-300'
                          }`}
                        >
                          <BookOpen className="h-3.5 w-3.5" />
                          <span>{subjectCount} / 10 môn</span>
                        </button>
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span className="inline-block px-2.5 py-0.5 rounded text-xs font-medium bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300">
                          {p.status}
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => openSubjectModal(p)}
                            className="inline-flex items-center gap-1 rounded-md border border-brand-200 bg-brand-50/50 px-2.5 py-1 text-xs font-semibold text-brand-600 shadow-sm transition hover:bg-brand-100 dark:border-brand-800/40 dark:bg-brand-950/30 dark:text-brand-400 dark:hover:bg-brand-900/40"
                          >
                            <List className="h-3 w-3" />
                            <span>DS Môn</span>
                          </button>
                          <button
                            onClick={() => handleDeleteProgram(p.program_id)}
                            className="inline-flex items-center gap-1 rounded-md border border-red-200 bg-red-50/50 px-2.5 py-1 text-xs font-semibold text-red-600 shadow-sm transition hover:bg-red-100 dark:border-red-800/40 dark:bg-red-950/30 dark:text-red-400 dark:hover:bg-red-900/40"
                          >
                            <Trash2 className="h-3 w-3" />
                            <span>Xóa</span>
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

      {/* Modal Thêm Chương Trình Đào Tạo Mới */}
      {isProgramModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
              Thêm Chương Trình Đào Tạo Mới
            </h2>
            <form onSubmit={handleCreateProgram} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Mã CTĐT (vd: PRG_DATA) *
                </label>
                <input
                  type="text"
                  required
                  value={progForm.program_id}
                  onChange={(e) => setProgForm({ ...progForm, program_id: e.target.value })}
                  placeholder="PRG_..."
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Tên Chương Trình *
                </label>
                <input
                  type="text"
                  required
                  value={progForm.program_name}
                  onChange={(e) => setProgForm({ ...progForm, program_name: e.target.value })}
                  placeholder="Ví dụ: Data Analytics Professional"
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Mô Tả
                </label>
                <textarea
                  rows={3}
                  value={progForm.description}
                  onChange={(e) => setProgForm({ ...progForm, description: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Phiên Bản
                  </label>
                  <input
                    type="text"
                    value={progForm.version}
                    onChange={(e) => setProgForm({ ...progForm, version: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Nhân Sự Quản Lý *
                  </label>
                  <select
                    value={progForm.manager_id}
                    onChange={(e) => setProgForm({ ...progForm, manager_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    {staffList.map((s) => (
                      <option key={s.staff_id} value={s.staff_id}>
                        {s.full_name} ({s.position})
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="mt-6 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsProgramModalOpen(false)}
                  className="rounded-lg px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-brand-500 px-5 py-2 text-sm font-medium text-white hover:bg-brand-600"
                >
                  Tạo Mới
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Quản Lý Môn Học trong CTĐT */}
      {selectedProgram && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-3xl max-h-[90vh] overflow-y-auto rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <div className="flex items-center justify-between border-b pb-4 dark:border-gray-800">
              <div>
                <h2 className="text-lg font-bold text-gray-900 dark:text-white">
                  Danh Sách Môn Học: {selectedProgram.program_name}
                </h2>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  Mã CTĐT: <span className="font-semibold">{selectedProgram.program_id}</span> • Hiện tại:{' '}
                  <span
                    className={`font-bold ${
                      subjects.length >= 10 ? 'text-amber-500' : 'text-brand-500'
                    }`}
                  >
                    {subjects.length} / 10 môn
                  </span>
                </p>
              </div>
              <button
                onClick={() => setSelectedProgram(null)}
                className="text-gray-400 hover:text-gray-600 dark:hover:text-white p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Form Thêm Môn Học Mới (Chặn khi đã đạt 10 môn) */}
            <div className="my-5 rounded-xl border border-gray-200 bg-gray-50/70 p-4 dark:border-gray-800 dark:bg-gray-800/40">
              <h3 className="flex items-center gap-1.5 text-sm font-semibold text-gray-900 dark:text-white mb-3">
                <Plus className="h-4 w-4" />
                <span>Thêm Môn Học Vào Chương Trình</span>
              </h3>
              {subjects.length >= 10 ? (
                <div className="flex items-center gap-2 rounded-lg bg-amber-50 p-3 text-xs font-semibold text-amber-800 dark:bg-amber-900/30 dark:text-amber-300">
                  <AlertTriangle className="h-4 w-4 text-amber-600" />
                  <span>Đã đạt giới hạn tối đa 10 môn học theo quy định của chương trình đào tạo!</span>
                </div>
              ) : (
                <form onSubmit={handleCreateSubject} className="grid grid-cols-1 gap-3 sm:grid-cols-4">
                  <div>
                    <label className="block text-[11px] font-semibold text-gray-700 dark:text-gray-300 mb-1">
                      Mã Môn *
                    </label>
                    <input
                      type="text"
                      required
                      value={subForm.subject_id}
                      onChange={(e) => setSubForm({ ...subForm, subject_id: e.target.value })}
                      className="w-full rounded-lg border border-gray-300 p-2 text-xs dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] font-semibold text-gray-700 dark:text-gray-300 mb-1">
                      Tên Môn Học *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="vd: Cơ sở dữ liệu SQL"
                      value={subForm.subject_name}
                      onChange={(e) => setSubForm({ ...subForm, subject_name: e.target.value })}
                      className="w-full rounded-lg border border-gray-300 p-2 text-xs dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] font-semibold text-gray-700 dark:text-gray-300 mb-1">
                      Số Giờ (Chẵn, vd: 30h = 15 buổi) *
                    </label>
                    <input
                      type="number"
                      step={2}
                      min={2}
                      required
                      value={subForm.total_hours}
                      onChange={(e) =>
                        setSubForm({ ...subForm, total_hours: parseInt(e.target.value, 10) })
                      }
                      className="w-full rounded-lg border border-gray-300 p-2 text-xs dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                    />
                  </div>
                  <div className="flex items-end gap-2">
                    <div className="flex-1">
                      <label className="block text-[11px] font-semibold text-gray-700 dark:text-gray-300 mb-1">
                        Loại Môn
                      </label>
                      <select
                        value={subForm.subject_type}
                        onChange={(e) =>
                          setSubForm({
                            ...subForm,
                            subject_type: e.target.value as 'CORE' | 'ELECTIVE',
                          })
                        }
                        className="w-full rounded-lg border border-gray-300 p-2 text-xs dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                      >
                        <option value="CORE">Bắt buộc (Core)</option>
                        <option value="ELECTIVE">Tự chọn (Elective)</option>
                      </select>
                    </div>
                    <button
                      type="submit"
                      className="rounded-lg bg-brand-500 px-4 py-2 text-xs font-semibold text-white hover:bg-brand-600 transition"
                    >
                      Lưu
                    </button>
                  </div>
                </form>
              )}
            </div>

            {/* Bảng Danh Sách Môn Học Hiện Có */}
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
                <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
                  <tr>
                    <th className="px-3 py-2.5">Mã Môn</th>
                    <th className="px-3 py-2.5">Tên Môn Học</th>
                    <th className="px-3 py-2.5 text-center">Thời Lượng</th>
                    <th className="px-3 py-2.5 text-center">Số Buổi (2h/buổi)</th>
                    <th className="px-3 py-2.5 text-center">Phân Loại</th>
                    <th className="px-3 py-2.5 text-right">Thao Tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                  {loadingSubjects ? (
                    <tr>
                      <td colSpan={6} className="py-6 text-center text-gray-400">
                        Đang tải danh sách môn...
                      </td>
                    </tr>
                  ) : subjects.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="py-6 text-center text-gray-400">
                        Chưa có môn học nào trong chương trình này
                      </td>
                    </tr>
                  ) : (
                    subjects.map((sub) => (
                      <tr key={sub.subject_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                        <td className="px-3 py-2.5 font-bold text-gray-900 dark:text-white text-xs">
                          {sub.subject_id}
                        </td>
                        <td className="px-3 py-2.5 font-medium text-gray-900 dark:text-white text-xs">
                          {sub.subject_name}
                        </td>
                        <td className="px-3 py-2.5 text-center text-xs">{sub.total_hours} giờ</td>
                        <td className="px-3 py-2.5 text-center text-xs font-semibold text-brand-600">
                          {sub.total_sessions} buổi
                        </td>
                        <td className="px-3 py-2.5 text-center">
                          <span
                            className={`inline-block px-2 py-0.5 rounded text-[10px] font-semibold ${
                              sub.subject_type === 'CORE'
                                ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
                                : 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
                            }`}
                          >
                            {sub.subject_type === 'CORE' ? 'Bắt buộc' : 'Tự chọn'}
                          </span>
                        </td>
                        <td className="px-3 py-2.5 text-right">
                          <button
                            onClick={() => handleDeleteSubject(sub.subject_id)}
                            className="inline-flex items-center gap-1 rounded-md border border-red-200 bg-red-50/50 px-2 py-0.5 text-xs font-semibold text-red-600 shadow-sm transition hover:bg-red-100 dark:border-red-800/40 dark:bg-red-950/30 dark:text-red-400 dark:hover:bg-red-900/40"
                          >
                            <Trash2 className="h-3 w-3" />
                            <span>Xóa</span>
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            <div className="mt-6 flex justify-end">
              <button
                onClick={() => setSelectedProgram(null)}
                className="rounded-lg bg-gray-100 dark:bg-gray-800 px-5 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-200"
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
