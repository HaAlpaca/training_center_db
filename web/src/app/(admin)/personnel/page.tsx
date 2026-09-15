'use client';

import React, { useState, useEffect } from 'react';
import {
  getStaffList,
  createStaff,
  getInstructorsList,
  createInstructor,
} from '@/actions/personnel';
import { GraduationCap, Building2, Plus, Shield, Crown } from 'lucide-react';

export default function PersonnelPage() {
  const [activeTab, setActiveTab] = useState<'instructors' | 'staff'>('instructors');
  const [instructors, setInstructors] = useState<any[]>([]);
  const [staffList, setStaffList] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  // Modal Instructor
  const [isInsModalOpen, setIsInsModalOpen] = useState(false);
  const [insForm, setInsForm] = useState({
    instructor_id: '',
    full_name: '',
    email: '',
    phone_number: '',
    specialization: 'Khoa học dữ liệu & AI',
    degree: 'Thạc sĩ',
    contract_type: 'FULLTIME' as 'FULLTIME' | 'PARTTIME',
  });

  // Modal Staff
  const [isStaffModalOpen, setIsStaffModalOpen] = useState(false);
  const [staffForm, setStaffForm] = useState({
    staff_id: '',
    full_name: '',
    gender: 1,
    date_of_birth: '1990-01-01',
    email: '',
    phone_number: '',
    position: 'Program Manager',
    manager_id: '',
  });

  const [alertMsg, setAlertMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadData = async () => {
    setLoading(true);
    const [insRes, staffRes] = await Promise.all([
      getInstructorsList(search),
      getStaffList(search),
    ]);
    if (insRes.success) setInstructors(insRes.data);
    if (staffRes.success) {
      setStaffList(staffRes.data);
      if (staffRes.data.length > 0 && !staffForm.manager_id) {
        setStaffForm((prev) => ({ ...prev, manager_id: staffRes.data[0].staff_id }));
      }
    }
    setLoading(false);
  };

  useEffect(() => {
    loadData();
  }, [search]);

  // Submit Instructor
  const handleCreateInstructor = async (e: React.FormEvent) => {
    e.preventDefault();
    setAlertMsg(null);
    const res = await createInstructor(insForm);
    if (res.success) {
      setAlertMsg({ text: res.message || 'Thêm giảng viên thành công!', type: 'success' });
      setIsInsModalOpen(false);
      setInsForm({
        instructor_id: '',
        full_name: '',
        email: '',
        phone_number: '',
        specialization: '',
        degree: 'Thạc sĩ',
        contract_type: 'FULLTIME',
      });
      loadData();
    } else {
      setAlertMsg({ text: res.error, type: 'error' });
    }
  };

  // Submit Staff
  const handleCreateStaff = async (e: React.FormEvent) => {
    e.preventDefault();
    setAlertMsg(null);
    const res = await createStaff(staffForm);
    if (res.success) {
      setAlertMsg({ text: res.message || 'Thêm nhân viên thành công!', type: 'success' });
      setIsStaffModalOpen(false);
      setStaffForm({
        staff_id: '',
        full_name: '',
        gender: 1,
        date_of_birth: '1990-01-01',
        email: '',
        phone_number: '',
        position: 'Coordinator',
        manager_id: staffList[0]?.staff_id || '',
      });
      loadData();
    } else {
      setAlertMsg({ text: res.error, type: 'error' });
    }
  };

  return (
    <div className="space-y-6">
      {/* Title */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Nhân Sự & Giảng Viên
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Quản lý đội ngũ giảng dạy, hợp đồng và cây phân cấp quản lý nhân sự
          </p>
        </div>
        {activeTab === 'instructors' ? (
          <button
            onClick={() => setIsInsModalOpen(true)}
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 transition"
          >
            <Plus className="h-4 w-4" />
            <span>Thêm Giảng Viên Mới</span>
          </button>
        ) : (
          <button
            onClick={() => setIsStaffModalOpen(true)}
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 transition"
          >
            <Plus className="h-4 w-4" />
            <span>Thêm Nhân Viên Mới</span>
          </button>
        )}
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

      {/* Tabs Switcher */}
      <div className="flex items-center gap-3 border-b border-gray-200 dark:border-gray-800">
        <button
          onClick={() => setActiveTab('instructors')}
          className={`flex items-center gap-2 pb-3 text-sm font-semibold transition border-b-2 ${
            activeTab === 'instructors'
              ? 'border-brand-500 text-brand-600 dark:text-brand-400'
              : 'border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400'
          }`}
        >
          <GraduationCap className="h-4 w-4" />
          <span>Đội Ngũ Giảng Viên ({instructors.length})</span>
        </button>
        <button
          onClick={() => setActiveTab('staff')}
          className={`flex items-center gap-2 pb-3 text-sm font-semibold transition border-b-2 ${
            activeTab === 'staff'
              ? 'border-brand-500 text-brand-600 dark:text-brand-400'
              : 'border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400'
          }`}
        >
          <Building2 className="h-4 w-4" />
          <span>Cây Phân Cấp Nhân Sự ({staffList.length})</span>
        </button>
      </div>

      {/* Search Input */}
      <div className="relative max-w-md">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={
            activeTab === 'instructors'
              ? 'Tìm theo tên giảng viên, chuyên môn...'
              : 'Tìm theo tên nhân viên, chức vụ...'
          }
          className="w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm text-gray-900 focus:border-brand-500 focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
        />
      </div>

      {/* Content for Instructors Tab */}
      {activeTab === 'instructors' && (
        <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
                <tr>
                  <th className="px-4 py-3.5">Mã GV</th>
                  <th className="px-4 py-3.5">Họ & Tên</th>
                  <th className="px-4 py-3.5">Học Vị</th>
                  <th className="px-4 py-3.5">Chuyên Môn</th>
                  <th className="px-4 py-3.5">Email & SĐT</th>
                  <th className="px-4 py-3.5 text-center">Hợp Đồng</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-gray-400">
                      Đang tải...
                    </td>
                  </tr>
                ) : instructors.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-gray-400">
                      Không tìm thấy giảng viên
                    </td>
                  </tr>
                ) : (
                  instructors.map((ins) => (
                    <tr key={ins.instructor_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5 font-bold text-xs text-gray-900 dark:text-white">
                        {ins.instructor_id}
                      </td>
                      <td className="px-4 py-3.5 font-semibold text-gray-900 dark:text-white">
                        {ins.full_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs text-gray-500">{ins.degree || '—'}</td>
                      <td className="px-4 py-3.5 text-xs font-medium text-brand-600">
                        {ins.specialization || '—'}
                      </td>
                      <td className="px-4 py-3.5 text-xs">
                        <span className="block text-gray-900 dark:text-white">{ins.email}</span>
                        <span className="text-gray-400 font-mono">{ins.phone_number}</span>
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span
                          className={`inline-block px-2.5 py-0.5 rounded text-xs font-semibold ${
                            ins.contract_type === 'FULLTIME'
                              ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
                              : 'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300'
                          }`}
                        >
                          {ins.contract_type}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Content for Staff Tab (Hierarchy) */}
      {activeTab === 'staff' && (
        <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/60 text-xs uppercase text-gray-500 dark:text-gray-400">
                <tr>
                  <th className="px-4 py-3.5">Mã NV</th>
                  <th className="px-4 py-3.5">Họ & Tên</th>
                  <th className="px-4 py-3.5">Vị Trí / Chức Vụ</th>
                  <th className="px-4 py-3.5">Email & SĐT</th>
                  <th className="px-4 py-3.5">Quản Lý Cấp Trên Trực Tiếp</th>
                  <th className="px-4 py-3.5 text-center">Trạng Thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-gray-400">
                      Đang tải...
                    </td>
                  </tr>
                ) : staffList.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-gray-400">
                      Không tìm thấy nhân viên
                    </td>
                  </tr>
                ) : (
                  staffList.map((stf) => (
                    <tr key={stf.staff_id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                      <td className="px-4 py-3.5 font-bold text-xs text-gray-900 dark:text-white">
                        {stf.staff_id}
                      </td>
                      <td className="px-4 py-3.5 font-semibold text-gray-900 dark:text-white">
                        {stf.full_name}
                      </td>
                      <td className="px-4 py-3.5 text-xs font-medium text-brand-600">
                        {stf.position}
                      </td>
                      <td className="px-4 py-3.5 text-xs">
                        <span className="block text-gray-900 dark:text-white">{stf.email}</span>
                        <span className="text-gray-400 font-mono">{stf.phone_number}</span>
                      </td>
                      <td className="px-4 py-3.5">
                        {stf.manager_name ? (
                          <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-gray-800 dark:text-gray-200">
                            <Shield className="h-3.5 w-3.5 text-brand-500" />
                            <span>{stf.manager_name} ({stf.manager_id})</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-bold bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">
                            <Crown className="h-3.5 w-3.5 text-amber-600" />
                            <span>Lãnh đạo cao nhất (Giám đốc)</span>
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span className="inline-block px-2.5 py-0.5 rounded text-xs font-semibold bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300">
                          {stf.status}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Modal Thêm Giảng Viên */}
      {isInsModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
              Thêm Giảng Viên Mới
            </h2>
            <form onSubmit={handleCreateInstructor} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Mã Giảng Viên *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="INS_..."
                    value={insForm.instructor_id}
                    onChange={(e) => setInsForm({ ...insForm, instructor_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Họ và Tên *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="ThS. Nguyễn Văn A"
                    value={insForm.full_name}
                    onChange={(e) => setInsForm({ ...insForm, full_name: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Email *
                  </label>
                  <input
                    type="email"
                    required
                    placeholder="instructor@gmail.com"
                    value={insForm.email}
                    onChange={(e) => setInsForm({ ...insForm, email: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Số Điện Thoại
                  </label>
                  <input
                    type="tel"
                    placeholder="0912345678"
                    value={insForm.phone_number}
                    onChange={(e) => setInsForm({ ...insForm, phone_number: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Học Vị
                  </label>
                  <input
                    type="text"
                    placeholder="Thạc sĩ / Tiến sĩ / Kỹ sư"
                    value={insForm.degree}
                    onChange={(e) => setInsForm({ ...insForm, degree: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Loại Hợp Đồng *
                  </label>
                  <select
                    value={insForm.contract_type}
                    onChange={(e) =>
                      setInsForm({
                        ...insForm,
                        contract_type: e.target.value as 'FULLTIME' | 'PARTTIME',
                      })
                    }
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    <option value="FULLTIME">Toàn thời gian (FULLTIME)</option>
                    <option value="PARTTIME">Bán thời gian (PARTTIME)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Chuyên Môn Giảng Dạy
                </label>
                <input
                  type="text"
                  placeholder="Data Engineering, Machine Learning, Fullstack..."
                  value={insForm.specialization}
                  onChange={(e) => setInsForm({ ...insForm, specialization: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                />
              </div>

              <div className="mt-6 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsInsModalOpen(false)}
                  className="rounded-lg px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-brand-500 px-5 py-2 text-sm font-medium text-white hover:bg-brand-600"
                >
                  Lưu Giảng Viên
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Thêm Nhân Viên (Cây phân cấp manager_id) */}
      {isStaffModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-900">
            <h2 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
              Thêm Nhân Viên (Phân Cấp Quản Lý)
            </h2>
            <form onSubmit={handleCreateStaff} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Mã Nhân Viên *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="STF_..."
                    value={staffForm.staff_id}
                    onChange={(e) => setStaffForm({ ...staffForm, staff_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Họ và Tên *
                  </label>
                  <input
                    type="text"
                    required
                    value={staffForm.full_name}
                    onChange={(e) => setStaffForm({ ...staffForm, full_name: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Chức Vụ *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Program Manager / Coordinator..."
                    value={staffForm.position}
                    onChange={(e) => setStaffForm({ ...staffForm, position: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Cấp Trên Quản Lý (Yêu cầu đề tài) *
                  </label>
                  <select
                    value={staffForm.manager_id}
                    onChange={(e) => setStaffForm({ ...staffForm, manager_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  >
                    {staffList.map((st) => (
                      <option key={st.staff_id} value={st.staff_id}>
                        {st.full_name} ({st.position})
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Email *
                  </label>
                  <input
                    type="email"
                    required
                    placeholder="name@system.edu.vn"
                    value={staffForm.email}
                    onChange={(e) => setStaffForm({ ...staffForm, email: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Số Điện Thoại
                  </label>
                  <input
                    type="tel"
                    placeholder="0912345678"
                    value={staffForm.phone_number}
                    onChange={(e) => setStaffForm({ ...staffForm, phone_number: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 p-2.5 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-white"
                  />
                </div>
              </div>

              <div className="mt-6 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsStaffModalOpen(false)}
                  className="rounded-lg px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-brand-500 px-5 py-2 text-sm font-medium text-white hover:bg-brand-600"
                >
                  Lưu Nhân Viên
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
