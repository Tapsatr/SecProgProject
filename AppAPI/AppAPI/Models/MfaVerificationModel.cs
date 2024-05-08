using System.ComponentModel.DataAnnotations;

namespace AppAPI.Models
{
    public class MfaVerificationModel
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        public string Token { get; set; }
    }
}