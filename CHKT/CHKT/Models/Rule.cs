using System;
using System.ComponentModel.DataAnnotations;

namespace CHKT.Models
{
    public class Rule
    {
        [Key]
        public int Id { get; set; }

        // Liên kết với Thiết bị bị quản lý
        public int DeviceId { get; set; }

        // Khung giờ cấm hoặc cho phép
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }

        // Lưu chuỗi tên các app bị cấm, ví dụ: "facebook,tiktok,youtube"
        public string BlockedApps { get; set; }
    }
}