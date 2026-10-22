using CHKT.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CHKT.Repositories
{
    public interface IRuleRepository
    {
        Task<IEnumerable<Rule>> GetAllAsync();
        Task<Rule> GetByIdAsync(int id);
        Task AddAsync(Rule rule);
        Task UpdateAsync(Rule rule);
        Task DeleteAsync(int id);
    }
}