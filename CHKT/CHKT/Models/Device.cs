using System.ComponentModel.DataAnnotations;

namespace CHKT.Models
{
    public class Device
    {
        [Key]
        public int Id { get; set; }
        public string DeviceName { get; set; }
        public string MacAddress { get; set; }
        public int ParentId { get; set; }
    }
}