using CHKT.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CHKT.Repositories
{
    public interface IChildRepository
    {
        Task<IEnumerable<Child>> GetAllAsync();
        Task<Child> GetByIdAsync(int id);
        Task AddAsync(Child child);
        Task UpdateAsync(Child child);
        Task DeleteAsync(int id);
    }
}