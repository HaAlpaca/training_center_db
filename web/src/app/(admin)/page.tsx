import React from 'react';
import type { Metadata } from 'next';
import { getDashboardData } from '@/actions/dashboard';
import Link from 'next/link';
import {
  Calendar,
  FileText,
  GraduationCap,
  BookOpen,
  School,
  Users,
  TrendingUp,
  PieChart,
  BarChart3,
  Award,
  ChevronRight,
} from 'lucide-react';
import CourseRevenueChart from '@/components/dashboard/CourseRevenueChart';
import ProgramDistributionChart from '@/components/dashboard/ProgramDistributionChart';
import SubjectPassRateChart from '@/components/dashboard/SubjectPassRateChart';
import InstructorStatsChart from '@/components/dashboard/InstructorStatsChart';

export const metadata: Metadata = {
  title: 'Hệ Thống Quản Lý Đào Tạo | Dashboard',
  description: 'Bảng điều khiển trung tâm quản lý đào tạo, sĩ số, doanh thu và kết quả học tập',
};

// Force dynamic so dashboard always shows real-time DB data
export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  const result = await getDashboardData();
  const {
    counts,
    enrollmentSummary,
    passRates,
    programDistribution = [],
    instructorDegrees = [],
    instructorContracts = [],
  } = result;

  return (
    <div className="space-y-6">
      {/* Header Title */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Bảng Điều Khiển Quản Lý Đào Tạo
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Hệ CSDL Quan Hệ PostgreSQL 16 • Đề tài 3 (STT 11_15)
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link
            href="/schedule"
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 transition shadow-sm"
          >
            <Calendar className="h-4 w-4" />
            <span>Xem Lịch Giảng Dạy</span>
          </Link>
          <Link
            href="/transcripts"
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-gray-100 dark:bg-gray-800 px-4 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-200 dark:hover:bg-gray-700 transition"
          >
            <FileText className="h-4 w-4" />
            <span>Tra Cứu Bảng Điểm</span>
          </Link>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {/* Card 1: Học viên */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm hover:shadow-md transition flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Tổng Số Học Viên</span>
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400">
                <GraduationCap className="h-5 w-5 text-blue-600 dark:text-blue-400" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-bold text-gray-900 dark:text-white">
                {counts.totalStudents}
              </span>
              <span className="text-xs text-green-600 font-medium">Học viên đang học</span>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-800">
            <Link
              href="/students"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand-600 dark:text-brand-400 hover:text-brand-700 transition"
            >
              <span>Xem danh sách học viên</span>
              <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
        </div>

        {/* Card 2: Chương trình đào tạo */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm hover:shadow-md transition flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Chương Trình Đào Tạo</span>
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400">
                <BookOpen className="h-5 w-5 text-purple-600 dark:text-purple-400" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-bold text-gray-900 dark:text-white">
                {counts.totalPrograms}
              </span>
              <span className="text-xs text-purple-600 font-medium">Đang vận hành</span>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-800">
            <Link
              href="/programs"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand-600 dark:text-brand-400 hover:text-brand-700 transition"
            >
              <span>Quản lý CTĐT & Môn học</span>
              <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
        </div>

        {/* Card 3: Khóa học / Lớp học */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm hover:shadow-md transition flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Lớp / Khóa Đào Tạo</span>
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400">
                <School className="h-5 w-5 text-amber-600 dark:text-amber-400" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-bold text-gray-900 dark:text-white">
                {counts.totalClasses}
              </span>
              <span className="text-xs text-amber-600 font-medium">Khóa học trong kỳ</span>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-800">
            <Link
              href="/classes"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand-600 dark:text-brand-400 hover:text-brand-700 transition"
            >
              <span>Xem chi tiết sĩ số</span>
              <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
        </div>

        {/* Card 4: Giảng viên & Nhân sự */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm hover:shadow-md transition flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-500 dark:text-gray-400">Giảng Viên & Nhân Viên</span>
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
                <Users className="h-5 w-5 text-emerald-600 dark:text-emerald-400" />
              </span>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-bold text-gray-900 dark:text-white">
                {counts.totalInstructors}
              </span>
              <span className="text-xs text-gray-500 font-medium">GV + {counts.totalStaff} NV</span>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-800">
            <Link
              href="/personnel"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand-600 dark:text-brand-400 hover:text-brand-700 transition"
            >
              <span>Quản lý đội ngũ nhân sự</span>
              <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
        </div>
      </div>

      {/* SECTION CHARTS 1: Doanh thu & Cơ cấu học viên */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
        {/* Biểu đồ Doanh thu & Sĩ số */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm lg:col-span-7">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="flex items-center gap-2 text-base font-semibold text-gray-900 dark:text-white">
                <TrendingUp className="h-5 w-5 text-brand-500" />
                <span>Biểu Đồ Doanh Thu & Sĩ Số Từng Khóa Đào Tạo</span>
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Đối chiếu tương quan giữa Doanh thu học phí (Triệu VNĐ) và Sĩ số học viên thực tế
              </p>
            </div>
            <span className="text-xs bg-brand-50 dark:bg-brand-900/30 text-brand-600 dark:text-brand-400 px-2.5 py-1 rounded-md font-medium">
              Biểu đồ Cột
            </span>
          </div>
          <CourseRevenueChart data={enrollmentSummary} />
        </div>

        {/* Biểu đồ Donut: Phân bổ học viên theo CTĐT */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm lg:col-span-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="flex items-center gap-2 text-base font-semibold text-gray-900 dark:text-white">
                <PieChart className="h-5 w-5 text-purple-500" />
                <span>Cơ Cấu Học Viên Theo Chương Trình</span>
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Tỷ trọng học viên & doanh thu đóng góp theo từng chuyên ngành
              </p>
            </div>
            <span className="text-xs bg-purple-50 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 px-2.5 py-1 rounded-md font-medium">
              Donut Chart
            </span>
          </div>
          <ProgramDistributionChart data={programDistribution} />
        </div>
      </div>

      {/* SECTION CHARTS 2: Tỷ lệ đạt môn học & Đội ngũ giảng viên */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
        {/* Biểu đồ Tỷ lệ đạt môn học */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm lg:col-span-7">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="flex items-center gap-2 text-base font-semibold text-gray-900 dark:text-white">
                <BarChart3 className="h-5 w-5 text-green-500" />
                <span>Tỷ Lệ Đạt (Pass Rate %) Từng Môn Học</span>
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Trực quan hóa tỷ lệ đỗ rớt của học viên qua các kỳ thi (Điểm &ge; 5.0)
              </p>
            </div>
            <Link
              href="/incomplete-students"
              className="inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-red-50/50 px-3 py-1.5 text-xs font-semibold text-red-600 shadow-sm transition hover:bg-red-100 dark:border-red-800/40 dark:bg-red-950/30 dark:text-red-400 dark:hover:bg-red-900/40"
            >
              <span>Xem nợ môn</span>
              <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
          <SubjectPassRateChart data={passRates} />
        </div>

        {/* Biểu đồ Phân bổ Đội ngũ Giảng viên */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm lg:col-span-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="flex items-center gap-2 text-base font-semibold text-gray-900 dark:text-white">
                <Award className="h-5 w-5 text-indigo-500" />
                <span>Cơ Cấu Học Vị & Hợp Đồng Giảng Viên</span>
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Phân bổ trình độ học vị (Tiến sĩ, Thạc sĩ, Kỹ sư) và loại hợp đồng
              </p>
            </div>
            <Link
              href="/personnel"
              className="inline-flex items-center gap-1.5 rounded-lg border border-indigo-200 bg-indigo-50/50 px-3 py-1.5 text-xs font-semibold text-indigo-600 shadow-sm transition hover:bg-indigo-100 dark:border-indigo-800/40 dark:bg-indigo-950/30 dark:text-indigo-400 dark:hover:bg-indigo-900/40"
            >
              <span>Chi tiết nhân sự</span>
              <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
          <InstructorStatsChart degrees={instructorDegrees} contracts={instructorContracts} />
        </div>
      </div>

      {/* Grid 2 bảng báo cáo chi tiết */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
        {/* Bảng 1: Thống kê sĩ số & Doanh thu học phí (View v_thong_ke_khoa_dao_tao) */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm lg:col-span-7">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-semibold text-gray-900 dark:text-white">
                Bảng Thống Kê Sĩ Số & Doanh Thu Chi Tiết
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Dữ liệu tính toán thời gian thực từ View <code className="text-brand-500">v_thong_ke_khoa_dao_tao</code>
              </p>
            </div>
            <span className="text-xs bg-brand-50 dark:bg-brand-900/30 text-brand-600 dark:text-brand-400 px-2.5 py-1 rounded-md font-medium">
              View PostgreSQL
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-xs uppercase text-gray-500 dark:text-gray-400">
                <tr>
                  <th className="px-3 py-2.5">Khóa Đào Tạo</th>
                  <th className="px-3 py-2.5">Chương Trình</th>
                  <th className="px-3 py-2.5 text-center">Sĩ Số / Tối Đa</th>
                  <th className="px-3 py-2.5 text-right">Doanh Thu Thu Được</th>
                  <th className="px-3 py-2.5 text-center">Trạng Thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {enrollmentSummary.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-6 text-center text-gray-400">
                      Chưa có dữ liệu khóa học
                    </td>
                  </tr>
                ) : (
                  enrollmentSummary.map((c: any) => {
                    const isFull = Number(c.current_students) >= Number(c.max_capacity);
                    return (
                      <tr key={c.class_id} className="hover:bg-gray-50/60 dark:hover:bg-gray-800/40">
                        <td className="px-3 py-3 font-medium text-gray-900 dark:text-white">
                          {c.class_name}
                          <span className="block text-[11px] text-gray-400">{c.class_id}</span>
                        </td>
                        <td className="px-3 py-3 text-xs">{c.program_name}</td>
                        <td className="px-3 py-3 text-center">
                          <span
                            className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${
                              isFull
                                ? 'bg-red-50 text-red-600 dark:bg-red-900/30 dark:text-red-400'
                                : 'bg-green-50 text-green-600 dark:bg-green-900/30 dark:text-green-400'
                            }`}
                          >
                            {c.current_students} / {c.max_capacity}
                          </span>
                          <span className="block text-[10px] text-gray-400">
                            (Còn {c.remaining_slots} chỗ)
                          </span>
                        </td>
                        <td className="px-3 py-3 text-right font-medium text-gray-900 dark:text-white">
                          {new Intl.NumberFormat('vi-VN', {
                            style: 'currency',
                            currency: 'VND',
                          }).format(Number(c.total_tuition_collected || 0))}
                        </td>
                        <td className="px-3 py-3 text-center">
                          <span className="inline-block px-2 py-0.5 rounded text-[11px] font-medium bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300">
                            {c.class_status}
                          </span>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Bảng 2: Thống kê tỷ lệ đỗ rớt môn học (View v_ty_le_dat_mon_hoc) */}
        <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900 shadow-sm lg:col-span-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-semibold text-gray-900 dark:text-white">
                Bảng Điểm Đạt Từng Môn Học
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                View <code className="text-brand-500">v_ty_le_dat_mon_hoc</code> (Điểm thi &ge; 5.0)
              </p>
            </div>
            <Link
              href="/incomplete-students"
              className="inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-red-50/50 px-3 py-1.5 text-xs font-semibold text-red-600 shadow-sm transition hover:bg-red-100 dark:border-red-800/40 dark:bg-red-950/30 dark:text-red-400 dark:hover:bg-red-900/40"
            >
              <span>Xem nợ môn</span>
              <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-xs uppercase text-gray-500 dark:text-gray-400">
                <tr>
                  <th className="px-3 py-2.5">Môn Học</th>
                  <th className="px-3 py-2.5 text-center">Dự Thi</th>
                  <th className="px-3 py-2.5 text-center">Đạt / Rớt</th>
                  <th className="px-3 py-2.5 text-right">Tỷ Lệ Đạt</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {passRates.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="py-6 text-center text-gray-400">
                      Chưa có kết quả thi môn học
                    </td>
                  </tr>
                ) : (
                  passRates.map((s: any, idx: number) => {
                    const passRate = parseFloat(s.pass_rate_percent || 0);
                    return (
                      <tr key={`${s.class_id}-${s.subject_id}-${idx}`} className="hover:bg-gray-50/60 dark:hover:bg-gray-800/40">
                        <td className="px-3 py-2.5">
                          <span className="font-medium text-gray-900 dark:text-white block truncate max-w-[150px]">
                            {s.subject_name}
                          </span>
                          <span className="text-[10px] text-gray-400">{s.class_name}</span>
                        </td>
                        <td className="px-3 py-2.5 text-center text-xs font-semibold">
                          {s.total_candidates}
                        </td>
                        <td className="px-3 py-2.5 text-center text-xs">
                          <span className="text-green-600 font-medium">{s.passed_count}</span> /{' '}
                          <span className="text-red-500 font-medium">{s.failed_count}</span>
                        </td>
                        <td className="px-3 py-2.5 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <span className="text-xs font-bold text-gray-900 dark:text-white">
                              {passRate}%
                            </span>
                            <div className="w-12 bg-gray-200 dark:bg-gray-700 h-1.5 rounded-full overflow-hidden">
                              <div
                                className={`h-full ${
                                  passRate >= 80
                                    ? 'bg-green-500'
                                    : passRate >= 50
                                    ? 'bg-amber-500'
                                    : 'bg-red-500'
                                }`}
                                style={{ width: `${passRate}%` }}
                              />
                            </div>
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
      </div>
    </div>
  );
}

