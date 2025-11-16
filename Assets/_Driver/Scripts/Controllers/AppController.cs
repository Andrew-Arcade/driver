using System.IO;
using UnityEngine;
using UnityEngine.UI;

public class AppController : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private SpriteRenderer spriteRenderer;
    [SerializeField] private Text titleText;
    [SerializeField] private Text developerText;

    [Header("Debug")]
    [SerializeField] private ONYX.AppProfile appProfile;

    public void SetupApp(ONYX.AppProfile _appProfile)
    {
        appProfile = _appProfile;

        string iconPath = Path.Combine(Application.dataPath, "..", "..", "data", appProfile.icon + ".png");

        if (File.Exists(iconPath))
        {
            byte[] imageData = File.ReadAllBytes(iconPath);
            Texture2D tex = new Texture2D(2, 2);
            tex.LoadImage(imageData);
            spriteRenderer.sprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f));
        }
        else
        {
            Debug.LogWarning("Missing icon at " + iconPath);
        }

        titleText.text = appProfile.title;
        developerText.text = appProfile.developer;
    }
}