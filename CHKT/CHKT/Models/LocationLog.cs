using System;
using System.ComponentModel.DataAnnotations;

namespace CHKT.Models
{
    public class LocationLog
    {
        [Key]
        public int Id { get; set; }
        public int DeviceId { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}