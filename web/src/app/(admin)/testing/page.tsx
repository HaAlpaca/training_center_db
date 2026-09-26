'use client';

import React, { useState, useEffect, useRef } from 'react';
import {
  ShieldCheck,
  RefreshCw,
  Zap,
  CheckCircle2,
  XCircle,
  Send,
  ArrowRight,
  Terminal,
  Trash2,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';

// ─── Log Types ────────────────────────────────────────────────────────────────
type LogLevel = 'info' | 'success' | 'error' | 'sql' | 'warn';
interface LogEntry {
  id: string;
  timestamp: string;
  level: LogLevel;
  message: string;
  detail?: string;
}

function nowStr() {
  return new Date().toLocaleTimeString('vi-VN', {
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    fractionalSecondDigits: 3,
  });
}
function mkLog(level: LogLevel, message: string, detail?: string): LogEntry {
  return { id: crypto.randomUUID(), timestamp: nowStr(), level, message, detail };
}

const LOG_COLORS: Record<LogLevel, string> = {
  info: 'text-sky-400', success: 'text-emerald-400',
  error: 'text-red-400', sql: 'text-amber-300', warn: 'text-yellow-400',
};
const LOG_BADGES: Record<LogLevel, string> = {
  info: 'bg-sky-900/60 text-sky-300', success: 'bg-emerald-900/60 text-emerald-300',
  error: 'bg-red-900/60 text-red-300', sql: 'bg-amber-900/60 text-amber-300',
  warn: 'bg-yellow-900/60 text-yellow-300',
};

// ─── Log Panel ────────────────────────────────────────────────────────────────
function LogPanel({ logs, onClear }: { logs: LogEntry[]; onClear: () => void }) {
  const bottomRef = useRef<HTMLDivElement>(null);
  const [collapsed, setCollapsed] = useState(false);

  useEffect(() => {
    if (!collapsed) bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [logs, collapsed]);

  return (
    <div className="mt-6 rounded-xl border border-gray-700 bg-gray-950 shadow-xl overflow-hidden">
      <div className="flex items-center justify-between px-4 py-2.5 bg-gray-900 border-b border-gray-700">
        <div className="flex items-center gap-2">
          <Terminal className="h-4 w-4 text-emerald-400" />
          <span className="text-sm font-semibold text-gray-200 font-mono">Execution Log</span>
          {logs.length > 0 && (
            <span className="rounded-full bg-gray-700 px-2 py-0.5 text-xs text-gray-300">{logs.length} entries</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button onClick={onClear} className="flex items-center gap-1 rounded px-2 py-1 text-xs text-gray-400 hover:bg-gray-700 hover:text-red-400 transition">
            <Trash2 className="h-3 w-3" /> Clear
          </button>
          <button onClick={() => setCollapsed(v => !v)} className="flex items-center gap-1 rounded px-2 py-1 text-xs text-gray-400 hover:bg-gray-700 hover:text-white transition">
            {collapsed ? <ChevronDown className="h-3 w-3" /> : <ChevronUp className="h-3 w-3" />}
            {collapsed ? 'Expand' : 'Collapse'}
          </button>
        </div>
      </div>
      {!collapsed && (
        <div className="h-72 overflow-y-auto p-3 space-y-1 font-mono text-xs">
          {logs.length === 0 ? (
            <p className="text-gray-600 italic text-center mt-8">Chưa có log nào. Hãy chạy một test hoặc transaction để bắt đầu...</p>
          ) : (
            logs.map(log => (
              <div key={log.id} className="flex gap-2 leading-relaxed">
                <span className="shrink-0 text-gray-600 select-none">[{log.timestamp}]</span>
                <span className={`shrink-0 rounded px-1.5 py-0 font-bold uppercase text-[10px] ${LOG_BADGES[log.level]}`}>{log.level}</span>
                <span className={`${LOG_COLORS[log.level]} break-all`}>
                  {log.message}
                  {log.detail && <span className="ml-1 text-gray-400 italic">{log.detail}</span>}
                </span>
              </div>
            ))
          )}
          <div ref={bottomRef} />
        </div>
      )}
    </div>
  );
}

import {
  runTriggerTest,
  executeTransaction1,
  executeTransaction2,
  executeTransaction3,
  executeTransaction4,
  executeTransaction5,
  getTestingMetadata,
} from '@/actions/testing';

export default function TestingPage() {
  const [activeTab, setActiveTab] = useState<'triggers' | 'transactions'>('triggers');
  const [loadingTestId, setLoadingTestId] = useState<number | null>(null);
  const [triggerResults, setTriggerResults] = useState<{ [key: number]: any }>({});
  const [metadata, setMetadata] = useState<any>({
    courses: [],
    students: [],
    subjects: [],
    instructors: [],
    rooms: [],
    classes: [],
  });

  // Transaction form states
  const [txLoading, setTxLoading] = useState<number | null>(null);
  const [txMessage, setTxMessage] = useState<{ [key: number]: { success: boolean; message?: string; error?: string } }>({});

  // Log states
  const [triggerLogs, setTriggerLogs] = useState<LogEntry[]>([]);
  const [txLogs, setTxLogs] = useState<LogEntry[]>([]);
  const addTriggerLog = (level: LogLevel, message: string, detail?: string) =>
    setTriggerLogs((prev) => [...prev, mkLog(level, message, detail)]);
  const addTxLog = (level: LogLevel, message: string, detail?: string) =>
    setTxLogs((prev) => [...prev, mkLog(level, message, detail)]);

  useEffect(() => {
    getTestingMetadata().then((res) => {
      if (res.success) {
        setMetadata(res);
      }
    });
  }, []);

  const handleTestTrigger = async (testCaseId: number, triggerName?: string) => {
    setLoadingTestId(testCaseId);
    addTriggerLog('info', `══ Bắt đầu Test Case ${testCaseId}${triggerName ? ': ' + triggerName : ''} ══`);
    addTriggerLog('sql',  `Thực thi SQL: DO $$ BEGIN ... INSERT vi phạm ràng buộc ... END $$;`);
    addTriggerLog('info', `Đang gửi lệnh đến PostgreSQL...`);
    try {
      const res = await runTriggerTest(testCaseId);
      setTriggerResults((prev) => ({ ...prev, [testCaseId]: res }));
      if (res.isTriggerBlocked) {
        addTriggerLog('success', `Trigger kích hoạt thành công! Vi phạm đã bị chặn.`);
        addTriggerLog('error',   `PostgreSQL EXCEPTION:`, res.sqlError);
        addTriggerLog('success', `✔ Test Case ${testCaseId} PASSED — Trigger hoạt động đúng.`);
      } else {
        addTriggerLog('warn',  `Trigger KHÔNG chặn được vi phạm!`);
        addTriggerLog('error', `✘ Test Case ${testCaseId} FAILED — Trigger không hoạt động.`);
      }
    } catch (err: any) {
      setTriggerResults((prev) => ({
        ...prev,
        [testCaseId]: { success: false, sqlError: err.message },
      }));
      addTriggerLog('error', `Lỗi hệ thống:`, err.message);
    } finally {
      addTriggerLog('info', `══ Kết thúc Test Case ${testCaseId} ══`);
      setLoadingTestId(null);
    }
  };

  const handleTx1 = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setTxLoading(1);
    const fd = new FormData(e.currentTarget);
    const maKhoa = fd.get('ma_khoa') as string;
    addTxLog('info', `══ Bắt đầu Transaction 1: sp_mo_khoa_dao_tao_moi ══`);
    addTxLog('sql',  `CALL sp_mo_khoa_dao_tao_moi('${maKhoa}', '${fd.get('ten_khoa')}', '${fd.get('ma_ctdt')}', '${fd.get('ma_ky_hoc')}', '${fd.get('ngay_bat_dau')}', '${fd.get('ngay_ket_thuc')}');`);
    addTxLog('info', `Step 1/3: Kiểm tra CTĐT và Kỳ học hợp lệ...`);
    addTxLog('info', `Step 2/3: INSERT INTO khoa_dao_tao...`);
    addTxLog('info', `Step 3/3: FOR LOOP tạo toàn bộ lớp môn học...`);
    const res = await executeTransaction1({
      ma_khoa: maKhoa,
      ten_khoa: fd.get('ten_khoa') as string,
      ma_ctdt: fd.get('ma_ctdt') as string,
      ma_ky_hoc: fd.get('ma_ky_hoc') as string,
      ngay_bat_dau: fd.get('ngay_bat_dau') as string,
      ngay_ket_thuc: fd.get('ngay_ket_thuc') as string,
    });
    setTxMessage((prev) => ({ ...prev, 1: res }));
    if (res.success) {
      addTxLog('success', `COMMIT — Transaction hoàn tất thành công.`);
      addTxLog('success', res.message ?? '');
    } else {
      addTxLog('error', `ROLLBACK — Transaction thất bại!`);
      addTxLog('error', `PostgreSQL Error:`, res.error);
    }
    addTxLog('info', `══ Kết thúc Transaction 1 ══`);
    setTxLoading(null);
  };

  const handleTx2 = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setTxLoading(2);
    const fd = new FormData(e.currentTarget);
    const maHv = fd.get('ma_hv') as string;
    const maKhoa = fd.get('ma_khoa') as string;
    const hocPhi = Number(fd.get('hoc_phi'));
    addTxLog('info', `══ Bắt đầu Transaction 2: sp_dang_ky_khoa_hoc_va_dong_phi ══`);
    addTxLog('sql',  `CALL sp_dang_ky_khoa_hoc_va_dong_phi('${maHv}', '${maKhoa}', ${hocPhi});`);
    addTxLog('info', `Step 1/3: Kiểm tra học viên và khóa học tồn tại...`);
    addTxLog('info', `Step 2/3: INSERT INTO dang_ky_khoa_hoc (trạng thái: DANG_HOC)...`);
    addTxLog('info', `Step 3/3: INSERT INTO hoc_phi (ghi nhận ${hocPhi.toLocaleString('vi-VN')} VNĐ)...`);
    const res = await executeTransaction2({ ma_hv: maHv, ma_khoa: maKhoa, hoc_phi: hocPhi });
    setTxMessage((prev) => ({ ...prev, 2: res }));
    if (res.success) {
      addTxLog('success', `COMMIT — Transaction hoàn tất thành công.`);
      addTxLog('success', res.message ?? '');
    } else {
      addTxLog('error', `ROLLBACK — Transaction thất bại!`);
      addTxLog('error', `PostgreSQL Error:`, res.error);
    }
    addTxLog('info', `══ Kết thúc Transaction 2 ══`);
    setTxLoading(null);
  };

  const handleTx3 = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setTxLoading(3);
    const fd = new FormData(e.currentTarget);
    const maLopMon = fd.get('ma_lop_mon') as string;
    addTxLog('info', `══ Bắt đầu Transaction 3: sp_phan_cong_va_len_lich_buoi_hoc ══`);
    addTxLog('sql',  `CALL sp_phan_cong_va_len_lich_buoi_hoc('${maLopMon}', '${fd.get('ma_gv_chinh')}', '${fd.get('ma_gv_ta') || null}', '${fd.get('ma_phong')}', ...);`);
    addTxLog('info', `Step 1/4: Kiểm tra lớp môn, giáo viên, phòng học hợp lệ...`);
    addTxLog('info', `Step 2/4: INSERT INTO phan_cong_giang_day (Giảng viên chính)...`);
    addTxLog('info', `Step 3/4: INSERT INTO phan_cong_giang_day (Trợ giảng, nếu có)...`);
    addTxLog('info', `Step 4/4: FOR LOOP tạo tất cả buổi học theo khoảng cách ngày...`);
    const res = await executeTransaction3({
      ma_lop_mon: maLopMon,
      ma_gv_chinh: fd.get('ma_gv_chinh') as string,
      ma_gv_ta: (fd.get('ma_gv_ta') as string) || undefined,
      ma_phong: fd.get('ma_phong') as string,
      ngay_bat_dau: fd.get('ngay_bat_dau') as string,
      gio_bat_dau: fd.get('gio_bat_dau') as string,
      khoang_cach_ngay: Number(fd.get('khoang_cach_ngay') || 3),
    });
    setTxMessage((prev) => ({ ...prev, 3: res }));
    if (res.success) {
      addTxLog('success', `COMMIT — Transaction hoàn tất thành công.`);
      addTxLog('success', res.message ?? '');
    } else {
      addTxLog('error', `ROLLBACK — Transaction thất bại!`);
      addTxLog('error', `PostgreSQL Error:`, res.error);
    }
    addTxLog('info', `══ Kết thúc Transaction 3 ══`);
    setTxLoading(null);
  };

  const handleTx4 = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setTxLoading(4);
    const fd = new FormData(e.currentTarget);
    const maHv = fd.get('ma_hv') as string;
    const maLopMon = fd.get('ma_lop_mon') as string;
    const diemThi = Number(fd.get('diem_thi'));
    addTxLog('info', `══ Bắt đầu Transaction 4: sp_ghi_nhan_ket_qua_thi ══`);
    addTxLog('sql',  `CALL sp_ghi_nhan_ket_qua_thi('${maHv}', '${maLopMon}', ${diemThi}, '${fd.get('ngay_thi')}', '${fd.get('ghi_chu') || ''}');`);
    addTxLog('info', `Step 1/4: Kiểm tra học viên đã đăng ký khóa chứa lớp môn ${maLopMon}...`);
    addTxLog('info', `Step 2/4: Tính toán số lần thi hiện tại (lan_thi auto-increment)...`);
    addTxLog('info', `Step 3/4: INSERT INTO ket_qua_thi (điểm=${diemThi}, ${diemThi > 5 ? 'KET_QUA=DAT' : 'KET_QUA=KHONG_DAT'})...`);
    addTxLog('info', `Step 4/4: Kiểm tra điều kiện tốt nghiệp khóa (tất cả môn > 5.0?)...`);
    const res = await executeTransaction4({
      ma_hv: maHv,
      ma_lop_mon: maLopMon,
      diem_thi: diemThi,
      ngay_thi: fd.get('ngay_thi') as string,
      ghi_chu: (fd.get('ghi_chu') as string) || undefined,
    });
    setTxMessage((prev) => ({ ...prev, 4: res }));
    if (res.success) {
      addTxLog('success', `COMMIT — Transaction hoàn tất thành công.`);
      addTxLog('success', res.message ?? '');
    } else {
      addTxLog('error', `ROLLBACK — Transaction thất bại!`);
      addTxLog('error', `PostgreSQL Error:`, res.error);
    }
    addTxLog('info', `══ Kết thúc Transaction 4 ══`);
    setTxLoading(null);
  };

  const handleTx5 = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setTxLoading(5);
    const fd = new FormData(e.currentTarget);
    const maHv = fd.get('ma_hv') as string;
    const maKhoaCu = fd.get('ma_khoa_cu') as string;
    const maKhoaMoi = fd.get('ma_khoa_moi') as string;
    addTxLog('info', `══ Bắt đầu Transaction 5: sp_chuyen_khoa_hoc_vien ══`);
    addTxLog('sql',  `CALL sp_chuyen_khoa_hoc_vien('${maHv}', '${maKhoaCu}', '${maKhoaMoi}');`);
    addTxLog('info', `Step 1/4: Kiểm tra học viên đang học tại khóa ${maKhoaCu}...`);
    addTxLog('info', `Step 2/4: UPDATE dang_ky_khoa_hoc → is_deleted=TRUE (khóa cũ)...`);
    addTxLog('info', `Step 3/4: INSERT INTO dang_ky_khoa_hoc (khóa mới: ${maKhoaMoi})...`);
    addTxLog('info', `Step 4/4: Kết chuyển bảo lưu 100% học phí sang khóa ${maKhoaMoi}...`);
    const res = await executeTransaction5({ ma_hv: maHv, ma_khoa_cu: maKhoaCu, ma_khoa_moi: maKhoaMoi });
    setTxMessage((prev) => ({ ...prev, 5: res }));
    if (res.success) {
      addTxLog('success', `COMMIT — Transaction hoàn tất thành công.`);
      addTxLog('success', res.message ?? '');
    } else {
      addTxLog('error', `ROLLBACK — Transaction thất bại!`);
      addTxLog('error', `PostgreSQL Error:`, res.error);
    }
    addTxLog('info', `══ Kết thúc Transaction 5 ══`);
    setTxLoading(null);
  };


  const triggersList = [
    {
      id: 1,
      name: 'Trigger 2: Chống trùng phòng học',
      triggerName: 'trg_kiem_tra_trung_phong (buoi_hoc)',
      scenario: 'Thử xếp một buổi học mới vào phòng LAB_301 vào ngày 2026-09-02 (18:30 - 20:30). Phòng này đã có lịch của lớp LM_CT01_K01_M01.',
      expected: 'Trigger sẽ chặn và bắn lỗi: "Phòng học LAB_301 đã có lịch học vào ngày 2026-09-02 trong khung giờ 18:30:00 - 20:30:00."',
    },
    {
      id: 2,
      name: 'Trigger 3: Chống trùng lịch giảng viên',
      triggerName: 'trg_kiem_tra_trung_lich_gv (buoi_hoc)',
      scenario: 'Thử xếp lịch dạy ở phòng khác (LAB_999) cùng giờ 18:30 - 20:30 ngày 2026-09-02 cho giảng viên GV01 (người đã có lịch dạy lớp LM_CT01_K01_M01).',
      expected: 'Trigger sẽ chặn và bắn lỗi: "Giáo viên GV01 đã có lịch giảng dạy vào ngày 2026-09-02 trong khung giờ 18:30:00 - 20:30:00."',
    },
    {
      id: 3,
      name: 'Trigger 1: Giới hạn tối đa 10 môn / CTĐT',
      triggerName: 'trg_kiem_tra_so_mon_ctdt (mon_hoc)',
      scenario: 'Thêm liên tục các môn học vào chương trình CT01 cho đến môn thứ 11.',
      expected: 'Trigger sẽ chặn môn thứ 11 và bắn lỗi: "Chương trình đào tạo CT01 đã có 10 môn học. Mỗi chương trình chỉ được phép có tối đa 10 môn học."',
    },
    {
      id: 4,
      name: 'Trigger 4: Giảng viên chính và Trợ giảng phải khác nhau',
      triggerName: 'trg_kiem_tra_phan_cong (phan_cong_giang_day)',
      scenario: 'Thử phân công GV01 (đang là Giảng viên chính của lớp LM_CT01_K01_M01) làm Trợ giảng của chính lớp đó.',
      expected: 'Trigger sẽ chặn và bắn lỗi: "Một giáo viên (GV01) không thể đồng thời giữ cả 2 vai trò Giảng viên và Trợ giảng trong cùng một lớp môn học."',
    },
    {
      id: 5,
      name: 'Trigger 5: Học viên chỉ được thi ở môn của khóa đã đăng ký',
      triggerName: 'trg_kiem_tra_hoc_vien_du_thi (ket_qua_thi)',
      scenario: 'Thử nhập điểm thi lớp môn LM_CT01_K01_M01 (thuộc khóa Data CT01) cho học viên HV007 (chỉ mới đăng ký khóa AI CT03).',
      expected: 'Trigger sẽ chặn và thông báo: "Học viên HV007 chưa đăng ký khóa đào tạo CT01-2026HK1-K01. Không thể ghi nhận kết quả thi!"',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">
            Trung Tâm Kiểm Thử & Quản Lý Giao Dịch (5 Triggers & 5 Transactions)
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Trực tiếp kích hoạt, kiểm chứng phản ứng của 5 Triggers PL/pgSQL và thực thi 5 Stored Procedures Transactions chuẩn ACID.
          </p>
        </div>

        {/* Tab switcher */}
        <div className="flex rounded-lg bg-gray-100 p-1 dark:bg-gray-800">
          <button
            onClick={() => setActiveTab('triggers')}
            className={`flex items-center gap-2 rounded-md px-4 py-2 text-sm font-medium transition ${
              activeTab === 'triggers'
                ? 'bg-brand-500 text-white shadow'
                : 'text-gray-600 hover:text-gray-900 dark:text-gray-300'
            }`}
          >
            <ShieldCheck className="h-4 w-4" />
            <span>5 Triggers Ràng Buộc</span>
          </button>
          <button
            onClick={() => setActiveTab('transactions')}
            className={`flex items-center gap-2 rounded-md px-4 py-2 text-sm font-medium transition ${
              activeTab === 'transactions'
                ? 'bg-brand-500 text-white shadow'
                : 'text-gray-600 hover:text-gray-900 dark:text-gray-300'
            }`}
          >
            <RefreshCw className="h-4 w-4" />
            <span>5 Transactions Giao Dịch</span>
          </button>
        </div>
      </div>

      {/* TAB 1: 5 TRIGGERS */}
      {activeTab === 'triggers' && (<>
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {triggersList.map((item) => {
            const result = triggerResults[item.id];
            const isLoading = loadingTestId === item.id;

            return (
              <div
                key={item.id}
                className="flex flex-col justify-between rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900"
              >
                <div>
                  <div className="flex items-center justify-between">
                    <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-600 dark:bg-brand-950/50 dark:text-brand-400">
                      Test Case {item.id}
                    </span>
                    <span className="font-mono text-xs text-gray-400">{item.triggerName}</span>
                  </div>

                  <h3 className="mt-3 text-lg font-bold text-gray-800 dark:text-white">{item.name}</h3>

                  <div className="mt-3 space-y-2 text-sm">
                    <p className="text-gray-600 dark:text-gray-300">
                      <strong className="text-gray-800 dark:text-gray-100">Kịch bản thử nghiệm:</strong> {item.scenario}
                    </p>
                    <p className="text-gray-500 dark:text-gray-400">
                      <strong>Kỳ vọng phản hồi:</strong> {item.expected}
                    </p>
                  </div>
                </div>

                <div className="mt-5 border-t border-gray-100 pt-4 dark:border-gray-800">
                  <div className="flex items-center justify-between">
                    <button
                      onClick={() => handleTestTrigger(item.id, item.triggerName)}
                      disabled={isLoading}
                      className="inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-red-700 disabled:opacity-50"
                    >
                      {isLoading ? (
                        <>
                          <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                          Đang gửi lệnh test...
                        </>
                      ) : (
                        <>
                          <Zap className="h-4 w-4" />
                          <span>Chạy Test Cố Tình Vi Phạm</span>
                        </>
                      )}
                    </button>

                    {result && (
                      <span
                        className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold ${
                          result.isTriggerBlocked
                            ? 'bg-green-100 text-green-800 dark:bg-green-950/60 dark:text-green-300'
                            : 'bg-red-100 text-red-800 dark:bg-red-950/60 dark:text-red-300'
                        }`}
                      >
                        {result.isTriggerBlocked ? (
                          <>
                            <CheckCircle2 className="h-3.5 w-3.5 text-green-600 dark:text-green-400" />
                            <span>Trigger Đã Chặn Thành Công</span>
                          </>
                        ) : (
                          <>
                            <XCircle className="h-3.5 w-3.5 text-red-600 dark:text-red-400" />
                            <span>Thất Bại</span>
                          </>
                        )}
                      </span>
                    )}
                  </div>

                  {result && result.sqlError && (
                    <div className="mt-3 rounded-lg bg-gray-50 p-3 font-mono text-xs text-gray-700 dark:bg-gray-800 dark:text-gray-200">
                      <strong>Phản hồi Exception từ PostgreSQL:</strong>
                      <pre className="mt-1 whitespace-pre-wrap text-red-600 dark:text-red-400">{result.sqlError}</pre>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
        <LogPanel logs={triggerLogs} onClear={() => setTriggerLogs([])} />
      </>)}


      {/* TAB 2: 5 TRANSACTIONS */}
      {activeTab === 'transactions' && (
        <div className="space-y-6">
          {/* TX 1 */}
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
            <div className="flex items-center justify-between">
              <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-600 dark:bg-blue-950/50 dark:text-blue-400">
                Transaction 1: `sp_mo_khoa_dao_tao_moi`
              </span>
              <span className="flex items-center gap-1 text-xs text-gray-400">
                <span>Tạo Khóa</span>
                <ArrowRight className="h-3 w-3" />
                <span>Tự sinh toàn bộ Lớp môn</span>
              </span>
            </div>
            <h3 className="mt-2 text-lg font-bold text-gray-800 dark:text-white">
              Mở Khóa Đào Tạo Mới & Tự Động Khởi Tạo Các Lớp Môn Học
            </h3>

            <form onSubmit={handleTx1} className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Mã Khóa</label>
                <input
                  name="ma_khoa"
                  defaultValue="CT01-2026HK2-K03"
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Tên Khóa Đào Tạo</label>
                <input
                  name="ten_khoa"
                  defaultValue="Khóa 03 - Data Science (Mùa Hè 2027)"
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Chương Trình Đào Tạo</label>
                <select
                  name="ma_ctdt"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  <option value="CT01">CT01 - Khoa Học Dữ Liệu</option>
                  <option value="CT02">CT02 - Lập Trình Web Fullstack</option>
                  <option value="CT03">CT03 - Trí Tuệ Nhân Tạo</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Kỳ Học</label>
                <select
                  name="ma_ky_hoc"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  <option value="2026HK1">2026HK1 - Học kỳ 1 Năm 2026</option>
                  <option value="2026HK2">2026HK2 - Học kỳ 2 Năm 2026</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Ngày Bắt Đầu</label>
                <input
                  name="ngay_bat_dau"
                  type="date"
                  defaultValue="2027-06-01"
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Ngày Kết Thúc</label>
                <input
                  name="ngay_ket_thuc"
                  type="date"
                  defaultValue="2027-09-30"
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>

              <div className="sm:col-span-3 flex justify-end">
                <button
                  type="submit"
                  disabled={txLoading === 1}
                  className="inline-flex items-center gap-2 rounded-lg bg-brand-500 px-5 py-2 text-sm font-semibold text-white shadow hover:bg-brand-600 disabled:opacity-50"
                >
                  <Send className="h-4 w-4" />
                  <span>{txLoading === 1 ? 'Đang thực thi Transaction...' : 'Chạy Transaction 1 (CALL sp_mo_khoa_dao_tao_moi)'}</span>
                </button>
              </div>
            </form>

            {txMessage[1] && (
              <div
                className={`mt-3 rounded-lg p-3 text-sm ${
                  txMessage[1].success
                    ? 'bg-green-50 text-green-700 dark:bg-green-950/50 dark:text-green-300'
                    : 'bg-red-50 text-red-700 dark:bg-red-950/50 dark:text-red-300'
                }`}
              >
                {txMessage[1].message || txMessage[1].error}
              </div>
            )}
          </div>

          {/* TX 2 */}
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
            <div className="flex items-center justify-between">
              <span className="rounded-full bg-purple-50 px-3 py-1 text-xs font-semibold text-purple-600 dark:bg-purple-950/50 dark:text-purple-400">
                Transaction 2: `sp_dang_ky_khoa_hoc_va_dong_phi`
              </span>
              <span className="text-xs text-gray-400">Đăng ký khóa & Ghi nhận nộp học phí</span>
            </div>
            <h3 className="mt-2 text-lg font-bold text-gray-800 dark:text-white">
              Đăng Ký Khóa Học & Nộp Học Phí Nguyên Tử
            </h3>

            <form onSubmit={handleTx2} className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Học Viên</label>
                <select
                  name="ma_hv"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.students.map((st: any) => (
                    <option key={st.ma_hv} value={st.ma_hv}>
                      {st.ma_hv} - {st.ho_ten}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Khóa Đào Tạo</label>
                <select
                  name="ma_khoa"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.courses.map((c: any) => (
                    <option key={c.ma_khoa} value={c.ma_khoa}>
                      {c.ma_khoa} - {c.ten_khoa}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Số Tiền Đóng (VNĐ)</label>
                <input
                  name="hoc_phi"
                  type="number"
                  defaultValue={8500000}
                  step={500000}
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>

              <div className="sm:col-span-3 flex justify-end">
                <button
                  type="submit"
                  disabled={txLoading === 2}
                  className="inline-flex items-center gap-2 rounded-lg bg-brand-500 px-5 py-2 text-sm font-semibold text-white shadow hover:bg-brand-600 disabled:opacity-50"
                >
                  <Send className="h-4 w-4" />
                  <span>{txLoading === 2 ? 'Đang thực thi Transaction...' : 'Chạy Transaction 2 (CALL sp_dang_ky_khoa_hoc_va_dong_phi)'}</span>
                </button>
              </div>
            </form>

            {txMessage[2] && (
              <div
                className={`mt-3 rounded-lg p-3 text-sm ${
                  txMessage[2].success
                    ? 'bg-green-50 text-green-700 dark:bg-green-950/50 dark:text-green-300'
                    : 'bg-red-50 text-red-700 dark:bg-red-950/50 dark:text-red-300'
                }`}
              >
                {txMessage[2].message || txMessage[2].error}
              </div>
            )}
          </div>

          {/* TX 3 */}
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
            <div className="flex items-center justify-between">
              <span className="rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-600 dark:bg-amber-950/50 dark:text-amber-400">
                Transaction 3: `sp_phan_cong_va_len_lich_buoi_hoc`
              </span>
              <span className="text-xs text-gray-400">Phân công GV & Tự động sinh N buổi học</span>
            </div>
            <h3 className="mt-2 text-lg font-bold text-gray-800 dark:text-white">
              Phân Công Giáo Viên & Tự Động Sinh Toàn Bộ Lịch Học
            </h3>

            <form onSubmit={handleTx3} className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Lớp Môn Học</label>
                <select
                  name="ma_lop_mon"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.classes.map((cl: any) => (
                    <option key={cl.ma_lop_mon} value={cl.ma_lop_mon}>
                      {cl.ma_lop_mon}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Giảng Viên Chính</label>
                <select
                  name="ma_gv_chinh"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.instructors.map((ins: any) => (
                    <option key={ins.ma_gv} value={ins.ma_gv}>
                      {ins.ma_gv} - {ins.ho_ten}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Trợ Giảng (Tùy chọn)</label>
                <select
                  name="ma_gv_ta"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  <option value="">-- Không có trợ giảng --</option>
                  {metadata.instructors.map((ins: any) => (
                    <option key={ins.ma_gv} value={ins.ma_gv}>
                      {ins.ma_gv} - {ins.ho_ten}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Phòng Học</label>
                <select
                  name="ma_phong"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.rooms.map((r: any) => (
                    <option key={r.ma_phong} value={r.ma_phong}>
                      {r.ma_phong} - {r.ten_phong}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Ngày Khai Giảng</label>
                <input
                  name="ngay_bat_dau"
                  type="date"
                  defaultValue="2027-03-01"
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Giờ Bắt Đầu</label>
                <input
                  name="gio_bat_dau"
                  type="time"
                  defaultValue="18:30"
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>

              <div className="sm:col-span-3 flex justify-end">
                <button
                  type="submit"
                  disabled={txLoading === 3}
                  className="inline-flex items-center gap-2 rounded-lg bg-brand-500 px-5 py-2 text-sm font-semibold text-white shadow hover:bg-brand-600 disabled:opacity-50"
                >
                  <Send className="h-4 w-4" />
                  <span>{txLoading === 3 ? 'Đang thực thi Transaction...' : 'Chạy Transaction 3 (CALL sp_phan_cong_va_len_lich_buoi_hoc)'}</span>
                </button>
              </div>
            </form>

            {txMessage[3] && (
              <div
                className={`mt-3 rounded-lg p-3 text-sm ${
                  txMessage[3].success
                    ? 'bg-green-50 text-green-700 dark:bg-green-950/50 dark:text-green-300'
                    : 'bg-red-50 text-red-700 dark:bg-red-950/50 dark:text-red-300'
                }`}
              >
                {txMessage[3].message || txMessage[3].error}
              </div>
            )}
          </div>

          {/* TX 4 */}
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
            <div className="flex items-center justify-between">
              <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-600 dark:bg-emerald-950/50 dark:text-emerald-400">
                Transaction 4: `sp_ghi_nhan_ket_qua_thi`
              </span>
              <span className="flex items-center gap-1 text-xs text-gray-400">
                <span>Nhập điểm thi</span>
                <ArrowRight className="h-3 w-3" />
                <span>Tự tăng lần thi</span>
                <ArrowRight className="h-3 w-3" />
                <span>Tự xét tốt nghiệp</span>
              </span>
            </div>
            <h3 className="mt-2 text-lg font-bold text-gray-800 dark:text-white">
              Ghi Nhận Kết Quả Thi & Tự Động Xét Tốt Nghiệp Khóa
            </h3>

            <form onSubmit={handleTx4} className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Học Viên</label>
                <select
                  name="ma_hv"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.students.map((st: any) => (
                    <option key={st.ma_hv} value={st.ma_hv}>
                      {st.ma_hv} - {st.ho_ten}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Lớp Môn Học</label>
                <select
                  name="ma_lop_mon"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.classes.map((cl: any) => (
                    <option key={cl.ma_lop_mon} value={cl.ma_lop_mon}>
                      {cl.ma_lop_mon}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Điểm Thi (Thang điểm 10)</label>
                <input
                  name="diem_thi"
                  type="number"
                  step="0.1"
                  min="0"
                  max="10"
                  defaultValue={8.5}
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Ngày Thi</label>
                <input
                  name="ngay_thi"
                  type="date"
                  defaultValue="2026-10-15"
                  required
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>
              <div className="sm:col-span-2">
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Ghi Chú Đánh Giá</label>
                <input
                  name="ghi_chu"
                  defaultValue="Điểm thi đánh giá kết thúc môn"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                />
              </div>

              <div className="sm:col-span-3 flex justify-end">
                <button
                  type="submit"
                  disabled={txLoading === 4}
                  className="inline-flex items-center gap-2 rounded-lg bg-brand-500 px-5 py-2 text-sm font-semibold text-white shadow hover:bg-brand-600 disabled:opacity-50"
                >
                  <Send className="h-4 w-4" />
                  <span>{txLoading === 4 ? 'Đang thực thi Transaction...' : 'Chạy Transaction 4 (CALL sp_ghi_nhan_ket_qua_thi)'}</span>
                </button>
              </div>
            </form>

            {txMessage[4] && (
              <div
                className={`mt-3 rounded-lg p-3 text-sm ${
                  txMessage[4].success
                    ? 'bg-green-50 text-green-700 dark:bg-green-950/50 dark:text-green-300'
                    : 'bg-red-50 text-red-700 dark:bg-red-950/50 dark:text-red-300'
                }`}
              >
                {txMessage[4].message || txMessage[4].error}
              </div>
            )}
          </div>

          {/* TX 5 */}
          <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
            <div className="flex items-center justify-between">
              <span className="rounded-full bg-rose-50 px-3 py-1 text-xs font-semibold text-rose-600 dark:bg-rose-950/50 dark:text-rose-400">
                Transaction 5: `sp_chuyen_khoa_hoc_vien`
              </span>
              <span className="text-xs text-gray-400">Chuyển khóa & Bảo lưu kết chuyển 100% học phí</span>
            </div>
            <h3 className="mt-2 text-lg font-bold text-gray-800 dark:text-white">
              Chuyển Khóa Học Viên & Kết Chuyển Bảo Lưu Học Phí
            </h3>

            <form onSubmit={handleTx5} className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Học Viên</label>
                <select
                  name="ma_hv"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.students.map((st: any) => (
                    <option key={st.ma_hv} value={st.ma_hv}>
                      {st.ma_hv} - {st.ho_ten}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Khóa Cũ Đang Học</label>
                <select
                  name="ma_khoa_cu"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.courses.map((c: any) => (
                    <option key={c.ma_khoa} value={c.ma_khoa}>
                      {c.ma_khoa}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 dark:text-gray-300">Khóa Mới Chuyển Đến</label>
                <select
                  name="ma_khoa_moi"
                  className="mt-1 w-full rounded-lg border border-gray-300 p-2 text-sm dark:border-gray-700 dark:bg-gray-800"
                >
                  {metadata.courses.map((c: any) => (
                    <option key={c.ma_khoa} value={c.ma_khoa}>
                      {c.ma_khoa}
                    </option>
                  ))}
                </select>
              </div>

              <div className="sm:col-span-3 flex justify-end">
                <button
                  type="submit"
                  disabled={txLoading === 5}
                  className="inline-flex items-center gap-2 rounded-lg bg-brand-500 px-5 py-2 text-sm font-semibold text-white shadow hover:bg-brand-600 disabled:opacity-50"
                >
                  <Send className="h-4 w-4" />
                  <span>{txLoading === 5 ? 'Đang thực thi Transaction...' : 'Chạy Transaction 5 (CALL sp_chuyen_khoa_hoc_vien)'}</span>
                </button>
              </div>
            </form>

            {txMessage[5] && (
              <div
                className={`mt-3 rounded-lg p-3 text-sm ${
                  txMessage[5].success
                    ? 'bg-green-50 text-green-700 dark:bg-green-950/50 dark:text-green-300'
                    : 'bg-red-50 text-red-700 dark:bg-red-950/50 dark:text-red-300'
                }`}
              >
                {txMessage[5].message || txMessage[5].error}
              </div>
            )}
          </div>
          <LogPanel logs={txLogs} onClear={() => setTxLogs([])} />
        </div>
      )}
    </div>
  );
}
