using System.ComponentModel.DataAnnotations;

namespace AppAPI.Models
{
    public class UserSettingsModel
    {
        [Required]
        public bool IsMfaEnabled { get; set; }
    }
}
