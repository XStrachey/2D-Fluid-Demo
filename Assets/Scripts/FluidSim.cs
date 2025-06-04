// FluidSim.cs (with Viscosity and Vorticity support)
using UnityEngine;
using UnityEngine.InputSystem;

public class FluidSim : MonoBehaviour {
    [Header("Shaders")]
    public Shader advectionShader;
    public Shader divergenceShader;
    public Shader pressureShader;
    public Shader gradientSubtractShader;
    public Shader splatVelocityShader;
    public Shader splatDyeShader;
    public Shader displayShader;
    public Shader vorticityShader;
    public Shader vorticityForceShader;

    [Header("Simulation Settings")]
    public int simResolution = 256;
    public int pressureIterations = 20;
    public float deltaTimeMin = 0.001f;
    public float deltaTimeMax = 0.033f;
    [Range(1000.0f, 10000.0f)]
    public float velocityMultiplier = 5000.0f; // Adjust to scale velocity input
    [Range(0.0f, 0.01f)]
    public float viscosity = 0.0f; // [0, 1] usually small
    [Range(0.0f, 0.01f)]
    public float decay = 0.0f; // [0, 1] usually small

    [Header("Splat Base Settings"), Range(0.0f, 0.001f)]
    public float splatRadius = 0.001f;

    [Header("Splat Dye Settings")]
    public Color splatDyeColor = new Color(1f, 0.5f, 0f, 1f);

    [Header("Vorticity Settings"), Range(0.0f, 1.0f)]
    public float curlStrength = 0.5f;

    private Material advectMat, divMat, pressMat, gradSubMat, splatVelMat, splatDyeMat, displayMat, vorticityMat, vorticityForceMat;
    private RenderTexture velocityA, velocityB;
    private RenderTexture pressureA, pressureB;
    private RenderTexture dyeA, dyeB;
    private RenderTexture divergenceRT, curlRT;

    Vector2 prevMouseUV;

    void ClearRT(RenderTexture rt, Color color) {
        RenderTexture.active = rt;
        GL.Clear(false, true, color);
        RenderTexture.active = null;
    }

    void Start() {
        velocityA = CreateRT();
        velocityB = CreateRT();
        pressureA = CreateRT();
        pressureB = CreateRT();
        dyeA = CreateRT();
        dyeB = CreateRT();
        divergenceRT = CreateRT();
        curlRT = CreateRT();

        ClearRT(velocityA, Color.black);
        ClearRT(velocityB, Color.black);
        ClearRT(dyeA, Color.black);
        ClearRT(dyeB, Color.black);
        ClearRT(curlRT, Color.black);
        ClearRT(divergenceRT, Color.black);

        advectMat = new Material(advectionShader);
        divMat = new Material(divergenceShader);
        pressMat = new Material(pressureShader);
        gradSubMat = new Material(gradientSubtractShader);
        splatVelMat = new Material(splatVelocityShader);
        splatDyeMat = new Material(splatDyeShader);
        displayMat = new Material(displayShader);
        vorticityMat = new Material(vorticityShader);
        vorticityForceMat = new Material(vorticityForceShader);
    }

    RenderTexture CreateRT() {
        RenderTexture rt = new RenderTexture(simResolution, simResolution, 0, RenderTextureFormat.ARGBFloat);
        rt.enableRandomWrite = false;
        rt.Create();
        return rt;
    }

    void SimulateFluid(float dt) {
        Vector2 mousePos = Mouse.current.position.ReadValue();
        Vector2 currMouseUV = new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
        Vector2 delta = currMouseUV - prevMouseUV;
        prevMouseUV = currMouseUV;
        float aspect = (float)Screen.width / Screen.height;

        if (Mouse.current.leftButton.isPressed)
        {
            // --- Splat Velocity ---
            splatVelMat.SetVector("_Point", currMouseUV);
            splatVelMat.SetFloat("_Radius", splatRadius);
            splatVelMat.SetVector("_Velocity", new Vector4(delta.x * 5000, delta.y * 5000, 0, 0));
            splatVelMat.SetFloat("_Aspect", (float)Screen.width / Screen.height);
            splatVelMat.SetTexture("_VelocityTex", velocityA);
            Graphics.Blit(velocityA, velocityB, splatVelMat);
            Swap(ref velocityA, ref velocityB);

            // --- Splat Dye ---
            splatDyeMat.SetVector("_Point", currMouseUV);
            splatDyeMat.SetFloat("_Radius", splatRadius);
            splatDyeMat.SetVector("_Color", splatDyeColor); // 可根据需要调整颜色
            splatDyeMat.SetFloat("_Aspect", (float)Screen.width / Screen.height);
            splatDyeMat.SetTexture("_DyeTex", dyeA);
            Graphics.Blit(dyeA, dyeB, splatDyeMat);
            Swap(ref dyeA, ref dyeB);
        }

        // --- Vorticity: Calculate Curl ---
        vorticityMat.SetTexture("_VelocityTex", velocityA);
        vorticityMat.SetVector("_MainTex_TexelSize", new Vector4(1.0f / simResolution, 1.0f / simResolution, 0, 0));
        Graphics.Blit(null, curlRT, vorticityMat);

        // --- Vorticity Confinement Force ---
        vorticityForceMat.SetTexture("_VelocityTex", velocityA);
        vorticityForceMat.SetTexture("_CurlTex", curlRT);
        vorticityForceMat.SetFloat("_Curl", curlStrength);
        vorticityForceMat.SetVector("_MainTex_TexelSize", new Vector4(1.0f / simResolution, 1.0f / simResolution, 0, 0));
        Graphics.Blit(velocityA, velocityB, vorticityForceMat);
        Swap(ref velocityA, ref velocityB);

        // --- Advect Velocity ---
        advectMat.SetTexture("_VelocityTex", velocityA);
        advectMat.SetTexture("_InputTex", velocityA);
        advectMat.SetFloat("_DeltaTime", dt);
        advectMat.SetFloat("_Dissipation", 1f - viscosity);
        advectMat.SetVector("_MainTex_TexelSize", new Vector4(1.0f / simResolution, 1.0f / simResolution, 0, 0));
        Graphics.Blit(velocityA, velocityB, advectMat);
        Swap(ref velocityA, ref velocityB);

        // --- Advect Dye ---
        advectMat.SetTexture("_VelocityTex", velocityA);
        advectMat.SetTexture("_InputTex", dyeA);
        advectMat.SetFloat("_DeltaTime", dt);
        advectMat.SetFloat("_Dissipation", 1f - decay);
        advectMat.SetVector("_MainTex_TexelSize", new Vector4(1.0f / simResolution, 1.0f / simResolution, 0, 0));
        Graphics.Blit(dyeA, dyeB, advectMat);
        Swap(ref dyeA, ref dyeB);

        // --- Compute Divergence ---
        divMat.SetTexture("_VelocityTex", velocityA);
        divMat.SetVector("_MainTex_TexelSize", new Vector4(1.0f / simResolution, 1.0f / simResolution, 0, 0));
        Graphics.Blit(null, divergenceRT, divMat);

        // --- Solve Pressure ---
        Graphics.Blit(null, pressureA, pressMat);
        for (int i = 0; i < pressureIterations; i++) {
            pressMat.SetTexture("_PressureTex", pressureA);
            pressMat.SetTexture("_DivergenceTex", divergenceRT);
            pressMat.SetVector("_MainTex_TexelSize", new Vector4(1.0f / simResolution, 1.0f / simResolution, 0, 0));
            Graphics.Blit(pressureA, pressureB, pressMat);
            Swap(ref pressureA, ref pressureB);
        }

        // --- Subtract Gradient ---
        gradSubMat.SetTexture("_PressureTex", pressureA);
        gradSubMat.SetTexture("_VelocityTex", velocityA);
        gradSubMat.SetVector("_MainTex_TexelSize", new Vector4(1.0f / simResolution, 1.0f / simResolution, 0, 0));
        Graphics.Blit(null, velocityB, gradSubMat);
        Swap(ref velocityA, ref velocityB);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        float dt = Mathf.Clamp(Time.deltaTime, deltaTimeMin, deltaTimeMax);
        SimulateFluid(dt);
        displayMat.SetTexture("_MainTex", dyeA);
        Graphics.Blit(dyeA, dest, displayMat);
    }

    void Swap(ref RenderTexture a, ref RenderTexture b) {
        RenderTexture tmp = a;
        a = b;
        b = tmp;
    }
}
