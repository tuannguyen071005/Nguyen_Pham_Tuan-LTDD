using CHKT.Models;
using CHKT.Repositories;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DeviceApiController : ControllerBase
    {
        private readonly IDeviceRepository _deviceRepository;

        public DeviceApiController(IDeviceRepository deviceRepository)
        {
            _deviceRepository = deviceRepository;
        }

        // 1. READ ALL (Lấy danh sách thiết bị)
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var devices = await _deviceRepository.GetAllDevicesAsync();
            return Ok(devices);
        }

        // 2. READ ONE (Lấy chi tiết 1 thiết bị theo ID)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var device = await _deviceRepository.GetDeviceByIdAsync(id);
            if (device == null)
                return NotFound(new { Message = "Không tìm thấy thiết bị" });

            return Ok(device);
        }

        // 3. CREATE (Thêm thiết bị mới)
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Device device)
        {
            await _deviceRepository.AddDeviceAsync(device);
            return Ok(new { Message = "Thêm thiết bị thành công" });
        }

        // 4. UPDATE (Cập nhật thông tin thiết bị)
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Device device)
        {
            if (id != device.Id)
                return BadRequest(new { Message = "ID không khớp" });

            var existingDevice = await _deviceRepository.GetDeviceByIdAsync(id);
            if (existingDevice == null)
                return NotFound(new { Message = "Không tìm thấy thiết bị để cập nhật" });

            // Cập nhật các trường dữ liệu
            existingDevice.DeviceName = device.DeviceName;
            existingDevice.MacAddress = device.MacAddress;
            existingDevice.ParentId = device.ParentId;

            await _deviceRepository.UpdateDeviceAsync(existingDevice);
            return Ok(new { Message = "Cập nhật thiết bị thành công" });
        }

        // 5. DELETE (Xóa thiết bị)
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existingDevice = await _deviceRepository.GetDeviceByIdAsync(id);
            if (existingDevice == null)
                return NotFound(new { Message = "Không tìm thấy thiết bị để xóa" });

            await _deviceRepository.DeleteDeviceAsync(id);
            return Ok(new { Message = "Xóa thiết bị thành công" });
        }
    }
}