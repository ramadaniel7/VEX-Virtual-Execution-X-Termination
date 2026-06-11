const { SlashCommandBuilder, EmbedBuilder } = require("discord.js");
module.exports = {
  data: new SlashCommandBuilder().setName("help").setDescription("Panduan VEX Anti-Cheat System"),
  async execute(interaction) {
    await interaction.reply({ ephemeral: true, embeds:[new EmbedBuilder().setColor(0x7289DA)
      .setTitle("🛡️ VEX Anti-Cheat — Panduan")
      .addFields(
        {name:"📋 Alur",value:"1️⃣ Gabung server\n2️⃣ `/create <PlaceId>` → dapat Secret Key\n3️⃣ Pasang di Roblox Studio (`VEX_Config`)\n4️⃣ Publish game → aktif!\n5️⃣ `/renewal` tiap 120 hari"},
        {name:"⚡ Commands",value:"`/create` `/cs` `/checkstatus` `/ct` `/checktimer` `/renewal` `/help`"},
        {name:"🛡️ Deteksi",value:"💨 Speed Hack • 🦅 Fly/Noclip • ⚡ Teleport\n🎯 Aimbot • 🤖 Auto-Farm • 👁️ ESP\n🦘 Inf Jump • 💀 Exploit Exec • 📋 Map Copy"},
        {name:"🌐 Global Ban",value:"Cheater kena ban di Map A → otomatis blocked di semua map VEX lainnya"},
        {name:"📌 Info",value:"⚠️ Max **5 PlaceId**/akun\n⚠️ License aktif **120 hari**\n⚠️ Log cheater disimpan **90 hari**"}
      ).setFooter({text:"VEX Anti-Cheat v2.0"}).setTimestamp()]
    });
  }
};
