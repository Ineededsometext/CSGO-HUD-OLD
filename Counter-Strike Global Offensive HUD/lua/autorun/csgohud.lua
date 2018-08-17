if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("CSGOHUDSETNW")

    resource.AddFile("resource/fonts/stratum.ttf")
    resource.AddFile("materials/csgohud/health.png")
    resource.AddFile("materials/csgohud/armor.png")
    resource.AddFile("materials/csgohud/bullet.png")

    CreateClientConVar("csgo_hud_toggle", "0", true, false, "Disables or enables the CS:GO HUD.")
    CreateClientConVar("csgo_hud_r", "200", true, false, "Use this to increase or decrease red.")
    CreateClientConVar("csgo_hud_g", "225", true, false, "Use this to increase or decrease green.")
    CreateClientConVar("csgo_hud_b", "180", true, false, "Use this to increase or decrease blue.")

    net.Receive("CSGOHUDSETNW", function()
        local netply = net.ReadEntity()
        netply:SetNWBool("CSGOHUDSHOOT", true)

        if not timer.Exists("CSGOHUDSHOOT"..netply:UserID()) then
            timer.Create("CSGOHUDSHOOT"..netply:UserID(), netply:GetActiveWeapon():SequenceDuration() * 0.25, 1, function()
                netply:SetNWBool("CSGOHUDSHOOT", false)
            end)
        end
    end)

    hook.Add("PlayerHurt", "PlayerHurt", function(ply)
        ply:SetNWBool("CSGOHUDHURT", true)

        if not timer.Exists("CSGOHUDHURT"..ply:UserID()) then
            timer.Create("CSGOHUDHURT"..ply:UserID(), 0.4, 1, function()
                ply:SetNWBool("CSGOHUDHURT", false)
            end)
        else
            timer.Adjust("CSGOHUDHURT"..ply:UserID(), 0.4, 1, function()
                ply:SetNWBool("CSGOHUDHURT", false)
            end)
        end
    end)

    concommand.Add("csgo_hud_reset", function()
        GetConVar("csgo_hud_toggle"):SetBool(false)
        GetConVar("csgo_hud_r"):SetInt(200)
        GetConVar("csgo_hud_g"):SetInt(225)
        GetConVar("csgo_hud_b"):SetInt(180)
    end)

    local weapon_, ammo_, oldammo_

    hook.Add("PlayerSwitchWeapon", "Switched Weapon", function()
        weapon_ = nil
        ammo_ = nil
        oldammo_ = nil
    end)
else if CLIENT then
        local hide = {
            ["CHudAmmo"] = true,
            ["CHudSecondaryAmmo"] = true,
            ["CHudHealth"] = true,
            ["CHudBattery"] = true
        }

        hook.Add("HUDShouldDraw", "DisableDefaultHUD", function(type)
            if hide[type] and GetConVar("csgo_hud_toggle"):GetBool() == false then return false end
        end)

        surface.CreateFont("GOFontLarge", {
            font = "StratumNo2",
            size = ScrW() * 0.025,
            weight = 600,
            antialiasing = true
        })

        surface.CreateFont("GOFontMedium", {
            font = "StratumNo2",
            size = ScrW() * 0.02,
            weight = 600,
            antialiasing = true
        })

        surface.CreateFont("GOFontSmall", {
            font = "StratumNo2",
            size = ScrW() * 0.015,
            weight = 600,
            antialiasing = true
        })

        local lr, lg, lb = GetConVar("csgo_hud_r"):GetInt(), GetConVar("csgo_hud_g"):GetInt(), GetConVar("csgo_hud_b"):GetInt()
        local lr2, lg2, lb2, la2, lposx2 = GetConVar("csgo_hud_r"):GetInt(), GetConVar("csgo_hud_g"):GetInt(), GetConVar("csgo_hud_b"):GetInt(), 255, ScrW() * 0.96

        hook.Add("Think", "Shoot", function()
            local ply = LocalPlayer()

            if IsValid(ply:GetActiveWeapon()) then
                ammo_ = ply:GetActiveWeapon():Clip1()
            end

            if ply:KeyDown(IN_ATTACK) and ammo_ < oldammo_ then
                net.Start("CSGOHUDSETNW")
                    net.WriteEntity(LocalPlayer())
                net.SendToServer()
            end

            if oldammo_ == nil or 0 then
                oldammo_ = ammo_
            end

            if ammo_ < oldammo_ then
                oldammo_ = ammo_
            end
        end)

        hook.Add("HUDPaint", "CS:GO HUD", function()
            
            if GetConVar("csgo_hud_toggle"):GetBool() == true then return end

            local ply = LocalPlayer()

            local r, g, b = GetConVar("csgo_hud_r"):GetInt(), GetConVar("csgo_hud_g"):GetInt(), GetConVar("csgo_hud_b"):GetInt()

            if r < 0 then
                ply:ConCommand("csgo_hud_r ".."200")
            end

            if g < 0 then
                ply:ConCommand("csgo_hud_g ".."225")
            end

            if b < 0 then
                ply:ConCommand("csgo_hud_b ".."180")
            end

            local health = LocalPlayer():Health()
            local armor = LocalPlayer():Armor()
            local noammo = {
                "weapon_bugbait",
                "weapon_physgun",
                "weapon_physcannon",
                "weapon_crowbar",
                "weapon_stunstick",
                "weapon_slam",
                "gmod_tool",
                "gmod_camera"
            }

            if health <= 20 then
                draw.RoundedBox(0, 0, ScrH() * 0.95655, ScrW() * 0.127, ScrH() * 0.05, Color(255, 55, 55, 100))
            end

            surface.SetDrawColor(Color(0, 0, 0, 225))
            surface.SetTexture(surface.GetTextureID("gui/gradient"))
	    surface.DrawTexturedRect(0, ScrH() * 0.956, ScrW() * 0.3, ScrH() * 0.05)
        
            if health > 20 then
                surface.SetDrawColor(Color(r, g, b, 150))
            else
                surface.SetDrawColor(Color(255, 25, 25, 150))
            end
	    surface.SetMaterial(Material("materials/csgohud/health.png"))
	    surface.DrawTexturedRect(ScrW() * 0.005, ScrH() * 0.967, ScrW() * 0.0156, ScrW() * 0.0156)

            if health > 20 then
                if health <= 100 then
                    draw.SimpleText(health, "GOFontLarge", ScrW() * 0.0415, ScrH() * 0.956, Color(r, g, b, 150), TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText("100+", "GOFontLarge", ScrW() * 0.0415, ScrH() * 0.956, Color(r, g, b, 150), TEXT_ALIGN_CENTER)
                end
            else
                draw.SimpleText(health, "GOFontLarge", ScrW() * 0.0415, ScrH() * 0.956, Color(255, 25, 25, 150), TEXT_ALIGN_CENTER)
            end
        
            if LocalPlayer():GetNWBool("CSGOHUDHURT") == false and health > 20 then
                lr = Lerp(4 * FrameTime(), lr, r)
                lg = Lerp(4 * FrameTime(), lg, g)
                lb = Lerp(4 * FrameTime(), lb, b)
                surface.SetDrawColor(Color(lr, lg, lb, 150))
            else
                lr = Lerp(4 * FrameTime(), lr, 255)
                lg = Lerp(4 * FrameTime(), lg, 25)
                lb = Lerp(4 * FrameTime(), lb, 25)
                surface.SetDrawColor(Color(lr, lg, lb, 150))
            end
            surface.DrawOutlinedRect(ScrW() * 0.064, ScrH() * 0.976, ScrW() * 0.0545, ScrH() * 0.016)
            
            surface.SetDrawColor(Color(0, 0, 0, 120))
            surface.DrawRect(ScrW() * 0.065, ScrH() * 0.977, ScrW() * 0.0535, ScrH() * 0.015)

            if LocalPlayer():GetNWBool("CSGOHUDHURT") == false and health > 20 then
                lr = Lerp(4 * FrameTime(), lr, r)
                lg = Lerp(4 * FrameTime(), lg, g)
                lb = Lerp(4 * FrameTime(), lb, b)
                surface.SetDrawColor(Color(lr, lg, lb, 150))
            else
                lr = Lerp(4 * FrameTime(), lr, 255)
                lg = Lerp(4 * FrameTime(), lg, 25)
                lb = Lerp(4 * FrameTime(), lb, 25)
                surface.SetDrawColor(Color(lr, lg, lb, 150))
            end

            surface.DrawRect(ScrW() * 0.0645, ScrH() * 0.977, math.Clamp(health / LocalPlayer():GetMaxHealth() * ScrW() * 0.0535, 0, ScrW() * 0.0535), ScrH() * 0.015)

            surface.SetDrawColor(Color(r, g, b, 150))
	    surface.SetMaterial(Material("materials/csgohud/armor.png"))
	    surface.DrawTexturedRect(ScrW() * 0.13, ScrH() * 0.967, ScrW() * 0.0156, ScrW() * 0.0156)

            if armor <= 100 then
                draw.SimpleText(armor, "GOFontLarge", ScrW() * 0.166, ScrH() * 0.956, Color(r, g, b, 150), TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("100+", "GOFontLarge", ScrW() * 0.166, ScrH() * 0.956, Color(r, g, b, 150), TEXT_ALIGN_CENTER)
            end

            surface.SetDrawColor(Color(234, 235, 207, 50))
            surface.DrawOutlinedRect(ScrW() * 0.19, ScrH() * 0.976, ScrW() * 0.0545, ScrH() * 0.016)
            
            surface.SetDrawColor(Color(0, 0, 0, 120))
            surface.DrawRect(ScrW() * 0.191, ScrH() * 0.977, ScrW() * 0.0535, ScrH() * 0.015)

            surface.SetDrawColor(Color(r, g, b, 150))
            surface.DrawRect(ScrW() * 0.191, ScrH() * 0.977, math.Clamp(LocalPlayer():Armor() / 100 * ScrW() * 0.0535, 0, ScrW() * 0.0535), ScrH() * 0.015)

            surface.SetDrawColor(Color(0, 0, 0, 255))
	    surface.SetTexture(surface.GetTextureID("gui/gradient"))
            surface.DrawTexturedRectRotated(ScrW() * 0.925, ScrH() * 0.978, ScrW() * 0.16, ScrW() * 0.025, 180)
        
            surface.SetDrawColor(Color(r, g, b, 255))
            surface.SetMaterial(Material("materials/csgohud/bullet.png"))

            local weapon = LocalPlayer():GetActiveWeapon()

            if weapon and weapon:IsValid() then
                local clip = weapon:Clip1() 
                local ammo = LocalPlayer():GetAmmoCount(weapon:GetPrimaryAmmoType())

                if not weapon.DrawAmmo == nil and not weapon.DrawAmmo or table.HasValue(noammo, weapon:GetClass()) then return end

                if clip == -1 or LocalPlayer():InVehicle() then
                    draw.SimpleText(ammo, "GOFontMedium", ScrW() * 0.935, ScrH() * 0.963, Color(r, g, b, 230), TEXT_ALIGN_CENTER)
                    
                    return
                end

                draw.SimpleText(clip, "GOFontLarge", ScrW() * 0.915, ScrH() * 0.956, Color(r, g, b, 230), TEXT_ALIGN_RIGHT)
                draw.SimpleText("/", "GOFontSmall", ScrW() * 0.925, ScrH() * 0.9675, Color(r, g, b, 230), TEXT_ALIGN_RIGHT)
                draw.SimpleText(ammo, "GOFontSmall", ScrW() * 0.927, ScrH() * 0.97, Color(r, g, b, 230), TEXT_ALIGN_LEFT)
                
                if clip >= 1 then
                    surface.DrawTexturedRectRotated(ScrW() * 0.96, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                    if clip == 1 then
                        if LocalPlayer():GetNWBool("CSGOHUDSHOOT") == false then
                            lr2 = Lerp(20 * FrameTime(), lr2, r)
                            lg2 = Lerp(20 * FrameTime(), lg2, g)
                            lb2 = Lerp(20 * FrameTime(), lb2, b)
                            la2 = Lerp(20 * FrameTime(), la2, 255)
                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(ScrW() * 0.96, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        else
                            lr2 = Lerp(10 * FrameTime(), lr2, 0)
                            lg2 = Lerp(10 * FrameTime(), lg2, 0)
                            lb2 = Lerp(10 * FrameTime(), lb2, 0)
                            la2 = Lerp(10 * FrameTime(), la2, 0)
                            lposx2 = Lerp(10 * FrameTime(), ScrW() * 0.96, ScrW() * 0.965)

                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(lposx2, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        end
                    end
                end

                if clip >= 2 then
                    surface.DrawTexturedRectRotated(ScrW() * 0.965, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                    if clip == 2 then
                        if LocalPlayer():GetNWBool("CSGOHUDSHOOT") == false then
                            lr2 = Lerp(20 * FrameTime(), lr2, r)
                            lg2 = Lerp(20 * FrameTime(), lg2, g)
                            lb2 = Lerp(20 * FrameTime(), lb2, b)
                            la2 = Lerp(20 * FrameTime(), la2, 255)
                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(ScrW() * 0.965, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        else
                            lr2 = Lerp(10 * FrameTime(), lr2, 0)
                            lg2 = Lerp(10 * FrameTime(), lg2, 0)
                            lb2 = Lerp(10 * FrameTime(), lb2, 0)
                            la2 = Lerp(10 * FrameTime(), la2, 0)
                            lposx2 = Lerp(10 * FrameTime(), ScrW() * 0.965, ScrW() * 0.97)

                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(lposx2, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        end
                    end
                end

                if clip >= 3 then
                    surface.DrawTexturedRectRotated(ScrW() * 0.97, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                    if clip == 3 then
                        if LocalPlayer():GetNWBool("CSGOHUDSHOOT") == false then
                            lr2 = Lerp(20 * FrameTime(), lr2, r)
                            lg2 = Lerp(20 * FrameTime(), lg2, g)
                            lb2 = Lerp(20 * FrameTime(), lb2, b)
                            la2 = Lerp(20 * FrameTime(), la2, 255)
                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(ScrW() * 0.97, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        else
                            lr2 = Lerp(10 * FrameTime(), lr2, 0)
                            lg2 = Lerp(10 * FrameTime(), lg2, 0)
                            lb2 = Lerp(10 * FrameTime(), lb2, 0)
                            la2 = Lerp(10 * FrameTime(), la2, 0)
                            lposx2 = Lerp(10 * FrameTime(), ScrW() * 0.97, ScrW() * 0.975)

                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(lposx2, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        end
                    end
                end

                if clip >= 4 then
                    surface.DrawTexturedRectRotated(ScrW() * 0.975, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                    if clip == 4 then
                        if LocalPlayer():GetNWBool("CSGOHUDSHOOT") == false then
                            lr2 = Lerp(20 * FrameTime(), lr2, r)
                            lg2 = Lerp(20 * FrameTime(), lg2, g)
                            lb2 = Lerp(20 * FrameTime(), lb2, b)
                            la2 = Lerp(20 * FrameTime(), la2, 255)
                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(ScrW() * 0.975, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        else
                            lr2 = Lerp(10 * FrameTime(), lr2, 0)
                            lg2 = Lerp(10 * FrameTime(), lg2, 0)
                            lb2 = Lerp(10 * FrameTime(), lb2, 0)
                            la2 = Lerp(10 * FrameTime(), la2, 0)
                            lposx2 = Lerp(10 * FrameTime(), ScrW() * 0.975, ScrW() * 0.98)

                            surface.SetDrawColor(lr2, lg2, lb2, la2)
                            surface.DrawTexturedRectRotated(lposx2, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                        end
                    end
                end

                if clip >= 5 then
                    if LocalPlayer():GetNWBool("CSGOHUDSHOOT") == false then
                        lr2 = Lerp(20 * FrameTime(), lr2, r)
                        lg2 = Lerp(20 * FrameTime(), lg2, g)
                        lb2 = Lerp(20 * FrameTime(), lb2, b)
                        la2 = Lerp(20 * FrameTime(), la2, 255)
                        surface.SetDrawColor(lr2, lg2, lb2, la2)
                        surface.DrawTexturedRectRotated(ScrW() * 0.98, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                    else
                        lr2 = Lerp(10 * FrameTime(), lr2, 0)
                        lg2 = Lerp(10 * FrameTime(), lg2, 0)
                        lb2 = Lerp(10 * FrameTime(), lb2, 0)
                        la2 = Lerp(10 * FrameTime(), la2, 0)
                        lposx2 = Lerp(10 * FrameTime(), ScrW() * 0.98, ScrW() * 0.985)

                        surface.SetDrawColor(lr2, lg2, lb2, la2)
                        surface.DrawTexturedRectRotated(lposx2, ScrH() * 0.982, ScrW() * 0.015, ScrW() * 0.0125, 0)
                    end
                end
            end
        end)
    end
end
