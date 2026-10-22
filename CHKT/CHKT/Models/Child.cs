using System.ComponentModel.DataAnnotations;

namespace CHKT.Models
{
    public class Child
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; }
        public int Age { get; set; }
        public string Avatar { get; set; }

        // Liên kết với tài khoản Phụ huynh (dựa trên cấu trúc Identity)
        public string ParentId { get; set; }
    }
}