const { SlashCommandBuilder, EmbedBuilder } = require("discord.js");
const { api } = require("../index");
module.exports = {
  data: new SlashCommandBuilder().setName("renewal").setDescription("Perpanjang Secret Key VEX (120 hari baru)").addStringOption(o=>o.setName("placeid").setDescription("Place ID").setRequired(true)),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const placeId = interaction.options.getString("placeid").trim();
    const data = await api("/api/license/renewal","POST",{discord_id:interaction.user.id,place_id:placeId}).catch(e=>({error:e.message}));
    if (!data.success) return interaction.editReply({embeds:[new EmbedBuilder().setColor(0xFF4444).setTitle("❌ Renewal Gagal").setDescription(data.message||data.error||"Pastikan PlaceId benar dan kamu pemiliknya.")]});
    const exp = new Date(data.expires_at).toLocaleDateString("id-ID",{day:"numeric",month:"long",year:"numeric"});
    await interaction.editReply({embeds:[new EmbedBuilder().setColor(0x00FF88).setTitle("🔄 Renewal Berhasil!")
      .addFields({name:"🔑 New Secret Key",value:`\`\`\`\n${data.secret_key}\n\`\`\``},{name:"📅 Expired Baru",value:exp,inline:true},{name:"⚠️ Penting",value:"Key lama **tidak valid** lagi. Update `VEX_Config` di Studio dan publish ulang!",inline:false})
      .setFooter({text:"VEX Anti-Cheat • Jangan share key ini!"}).setTimestamp()]});
  }
};
