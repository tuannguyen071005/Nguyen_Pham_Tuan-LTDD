using CHKT.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CHKT.Repositories
{
    public interface IDeviceRepository
    {
        Task<IEnumerable<Device>> GetAllDevicesAsync();
        Task<Device> GetDeviceByIdAsync(int id);
        Task AddDeviceAsync(Device device);
        Task UpdateDeviceAsync(Device device);
        Task DeleteDeviceAsync(int id);
    }
}