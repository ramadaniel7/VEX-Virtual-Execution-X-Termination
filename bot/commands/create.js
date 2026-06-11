const { SlashCommandBuilder, EmbedBuilder } = require("discord.js");
const { api } = require("../index");

module.exports = {
  data: new SlashCommandBuilder().setName("create")
    .setDescription("Daftarkan PlaceId & dapatkan Secret Key VEX")
    .addStringOption(o => o.setName("placeid").setDescription("Place ID Roblox kamu").setRequired(true)),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const placeId = interaction.options.getString("placeid").trim();
    if (!/^\d+$/.test(placeId)) return interaction.editReply({ embeds:[err("PlaceId harus berupa angka!")] });

    const data = await api("/api/license/create", "POST", {
      discord_id: interaction.user.id, discord_tag: interaction.user.username, place_id: placeId
    }).catch(e => ({ error: e.message }));

    if (data.error === "MAX_PLACES_REACHED")
      return interaction.editReply({ embeds:[err("⚠️ Batas 5 PlaceId tercapai!", "Hapus salah satu atau hubungi admin untuk upgrade.")] });
    if (data.error === "PLACE_EXISTS")
      return interaction.editReply({ embeds:[err("PlaceId sudah terdaftar!", `Gunakan \`/renewal ${placeId}\` untuk perbarui key.`)] });
    if (!data.success)
      return interaction.editReply({ embeds:[err("Gagal membuat license", data.error || "Unknown error")] });

    const exp = new Date(data.expires_at).toLocaleDateString("id-ID",{day:"numeric",month:"long",year:"numeric"});
    await interaction.editReply({ embeds:[new EmbedBuilder().setColor(0x00FF88).setTitle("✅ License Berhasil Dibuat!")
      .setDescription("🔐 **Secret Key di bawah — JANGAN share ke siapapun!**")
      .addFields(
        {name:"🎮 Place ID", value:`\`${placeId}\``, inline:true},
        {name:"📅 Expired",  value:exp, inline:true},
        {name:"🔑 Secret Key", value:`\`\`\`\n${data.secret_key}\n\`\`\``},
        {name:"📋 Cara Pasang", value:"1. Buka Roblox Studio → ServerScriptService → VEX\n2. Edit `VEX_Config` → isi SECRET_KEY\n3. Edit `VEX_BackendURL` → isi URL backend\n4. Publish game!\n\nKetik `/help` untuk panduan lengkap."}
      ).setFooter({text:"VEX Anti-Cheat • Key hanya tampil sekali!"}).setTimestamp()]
    });
  }
};

const err = (title, desc="") => new EmbedBuilder().setColor(0xFF4444).setTitle("❌ "+title).setDescription(desc).setFooter({text:"VEX Anti-Cheat"});
