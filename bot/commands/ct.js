const { SlashCommandBuilder, EmbedBuilder } = require("discord.js");
const { api } = require("../index");

const exec = async (interaction) => {
  await interaction.deferReply({ ephemeral: true });
  const placeId = interaction.options.getString("placeid").trim();
  const data = await api(`/api/license/status/${placeId}`).catch(() => ({}));
  if (!data.found) return interaction.editReply({ content: `❌ PlaceId \`${placeId}\` tidak ditemukan.` });

  const exp  = new Date(data.expires_at);
  const dl   = data.days_left;
  const color= dl<=0?0xFF0000:dl<=7?0xFF4444:dl<=14?0xFF8800:0x00FF88;
  const warn = dl<=0?"🆘 EXPIRED — Gunakan /renewal sekarang!":dl<=7?"🔴 Segera renewal!":dl<=14?"🟡 Bersiap renewal.":"🟢 Aman.";

  await interaction.editReply({ embeds:[new EmbedBuilder().setColor(color).setTitle(`⏱️ Timer — ${placeId}`)
    .setDescription(warn)
    .addFields(
      {name:"Sisa",value:dl<=0?"EXPIRED":`**${dl}** hari`,inline:true},
      {name:"Tanggal",value:`<t:${Math.floor(exp/1000)}:F>`,inline:true},
      {name:"Relative",value:`<t:${Math.floor(exp/1000)}:R>`,inline:true},
    ).setFooter({text:"VEX Anti-Cheat"}).setTimestamp()]
  });
};

module.exports = { data: new SlashCommandBuilder().setName("ct").setDescription("Cek timer license VEX").addStringOption(o=>o.setName("placeid").setDescription("Place ID").setRequired(true)), execute: exec };
