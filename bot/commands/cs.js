const { SlashCommandBuilder, EmbedBuilder } = require("discord.js");
const { api } = require("../index");

const exec = async (interaction) => {
  await interaction.deferReply({ ephemeral: true });
  const placeId = interaction.options.getString("placeid").trim();
  const data = await api(`/api/license/status/${placeId}`).catch(() => ({ error: true }));
  if (!data.found) return interaction.editReply({ content: `❌ PlaceId \`${placeId}\` tidak terdaftar. Gunakan \`/create ${placeId}\`` });

  const color = data.expired ? 0xFF4444 : data.is_tampered ? 0xFF8800 : data.is_active ? 0x00FF88 : 0xFF4444;
  const status = data.is_tampered ? "⚠️ TAMPERED" : data.expired ? "❌ EXPIRED" : data.is_active ? "✅ AKTIF" : "🔴 REVOKED";
  const exp = new Date(data.expires_at);

  await interaction.editReply({ embeds:[new EmbedBuilder().setColor(color).setTitle(`🛡️ Status License — ${placeId}`)
    .addFields(
      {name:"Status",value:status,inline:true},
      {name:"Sisa",value:`**${data.days_left}** hari`,inline:true},
      {name:"Expired",value:`<t:${Math.floor(exp/1000)}:D>`,inline:true},
      {name:"Last Seen",value:data.last_seen?`<t:${Math.floor(new Date(data.last_seen)/1000)}:R>`:"Belum connect",inline:true},
      {name:"Owner",value:`<@${data.discord_id}>`,inline:true},
    ).setFooter({text:"VEX Anti-Cheat"}).setTimestamp()]
  });
};

module.exports = { data: new SlashCommandBuilder().setName("cs").setDescription("Cek status license VEX").addStringOption(o=>o.setName("placeid").setDescription("Place ID").setRequired(true)), execute: exec };
