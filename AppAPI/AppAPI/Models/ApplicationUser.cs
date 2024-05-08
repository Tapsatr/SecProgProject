using Microsoft.AspNetCore.Identity;

namespace AppAPI.Models
{
    public class ApplicationUser : IdentityUser
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public bool IsMfaEnabled { get; set; } = false;
    }
}
